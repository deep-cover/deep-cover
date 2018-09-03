# frozen_string_literal: true

module DeepCover
  # Base class to handle covered nodes.
  class Node
    include Mixin
    include HasTracker
    include HasChild
    include HasChildHandler
    include CanAugmentChildren
    include Rewriting
    extend CheckCompletion
    include FlowAccounting
    include IsStatement
    include ExecutionLocation
    include ChildCanBeEmpty
    include Filters
    extend Filters::ClassMethods

    attr_reader :index, :parent, :children, :base_node

    def initialize(base_node, parent:, index: 0, base_children: base_node.children)
      @base_node = base_node
      @parent = parent
      @index = index
      @children = []
      begin
        @children = augment_children(base_children)
        initialize_siblings
        super()
      rescue StandardError => e
        diagnose(e)
      end
    end

    ### Public API

    # Search self and descendants for a particular Class or type
    def find_all(lookup)
      case lookup
      when ::Module
        each_node.grep(lookup)
      when ::Symbol
        each_node.find_all { |n| n.type == lookup }
      when ::String
        each_node.find_all { |n| n.source == lookup }
      when ::Regexp
        each_node.find_all { |n| n.source =~ lookup }
      else
        raise ::TypeError, "Expected class or symbol, got #{lookup.class}: #{lookup.inspect}"
      end
    end

    # Shortcut to access children
    def [](lookup)
      if lookup.is_a?(Integer)
        children.fetch(lookup)
      else
        found = find_all(lookup)
        case found.size
        when 1
          found.first
        when 0
          raise "No children of type #{lookup}"
        else
          raise "Ambiguous lookup #{lookup}, found #{found}."
        end
      end
    end

    # Shortcut to create a node from source code
    def self.[](source)
      CoveredCode.new(source: source).execute_code.covered_ast
    end

    def children_nodes
      children.select { |c| c.is_a? Node }
    end
    alias_method :children_nodes_in_flow_order, :children_nodes

    attr_accessor :next_sibling
    attr_accessor :previous_sibling
    protected :next_sibling=, :previous_sibling=
    def initialize_siblings
      children_nodes_in_flow_order.each_cons(2) do |child, next_child|
        child.next_sibling = next_child
        next_child.previous_sibling = child
      end
    end
    private :initialize_siblings

    # Adapted from https://github.com/whitequark/ast/blob/master/lib/ast/node.rb
    def to_s(indent = 0)
      [
        '  ' * indent,
        '(',
        fancy_type,
        *children.map do |child, idx|
          if child.is_a?(Node)
            "\n#{child.to_s(indent + 1)}"
          else
            " #{child.inspect}"
          end
        end,
        ')',
      ].join
    end

    alias_method :inspect, :to_s
    ### Internal API

    def covered_code
      parent.covered_code
    end

    def type
      return base_node.type if base_node
      self.class.name.split('::').last.to_sym
    end

    def each_node(order = :postorder, &block)
      return to_enum :each_node, order unless block_given?
      yield self unless order == :postorder
      children_nodes.each do |child|
        child.each_node(order, &block)
      end
      yield self if order == :postorder
      self
    end

    def fancy_type
      class_name = self.class.to_s.gsub(/^DeepCover::/, '').gsub(/^Node::/, '')
      t = type.to_s
      t.casecmp(class_name) == 0 ? t : "#{t}[#{class_name}]"
    end

    private

    def diagnose(exception)
      msg = if self.class == Node
              "Unknown node type encountered: #{base_node.type}"
            else
              "Node class #{self.class} incorrectly defined"
            end
      warn [msg,
            'Attempting to continue, but this node will not be handled properly',
            ('Its subnodes will be ignored' if children.empty?),
            'Source:',
            expression,
            'Original exception:',
            exception.inspect,
      ].join("\n")
    end
  end
end
