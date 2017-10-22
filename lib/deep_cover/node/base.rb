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

    attr_reader :index, :parent, :children, :base_node

    def initialize(base_node, parent: raise, index: 0, base_children: base_node.children)
      @base_node = base_node
      @parent = parent
      @index = index
      @children = augment_children(base_children)
      super()
    end

    ### High level API for coverage purposes

    def [](v)
      children[v]
    end

    ### Public API

    def children_nodes
      children.select{|c| c.is_a? Node }
    end
    alias_method :children_nodes_in_flow_order, :children_nodes

    def next_sibling
      parent.children_nodes_in_flow_order.each_cons(2) do |child, next_child|
        return next_child if child.equal? self
      end
      nil
    end

    def previous_sibling
      parent.children_nodes_in_flow_order.each_cons(2) do |previous_child, child|
        return previous_child if child.equal? self
      end
      nil
    end

    # Adapted from https://github.com/whitequark/ast/blob/master/lib/ast/node.rb
    def to_s(indent=0)
      [
        "  " * indent,
        '(',
        fancy_type,
        *children.map do |child, idx|
          if child.is_a?(Node)
            "\n#{child.to_s(indent + 1)}"
          else
            " #{child.inspect}"
          end
        end,
        ')'
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

    def each_branch(order = :postorder, &block)
      return to_enum :each_branch, order unless block_given?
      each_node(order) { |node| yield node if node.is_a? Branch }
    end

    def fancy_type
      class_name = self.class.to_s.gsub(/^DeepCover::/,'').gsub(/^Node::/, '')
      t = type.to_s
      t.casecmp(class_name) == 0 ? t : "#{t}[#{class_name}]"
    end

  end
end
