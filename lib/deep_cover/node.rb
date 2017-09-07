module DeepCover
  class Node < Parser::AST::Node
  end
end

require_relative_dir 'node_behavior'
require_relative_dir 'node'

module DeepCover
  # Base class to handle covered nodes.
  class Node < Parser::AST::Node
    attr_reader :context, :nb, :parent

    def initialize(base_node, context, parent = nil)
      @context = context
      augmented_children = base_node.children.map { |child| self.class.augment(child, context, self) }
      @nb = context.create_node_nb
      @parent = parent
      super(base_node.type, augmented_children, location: base_node.location)
    end

    ### High level API for coverage purposes

    # Returns an array of character numbers (in the original buffer) that
    # pertain exclusively to this node (and thus not to any children).
    def proper_range
      location.expression.to_a - children.flat_map{|n| n.respond_to?(:location) && n.location && n.location.expression.to_a }
    end

    # Returns true iff it is executable. Keywords like `end` are not executable, but literals like `42` are executable.
    def executable?
      true
    end

    # Returns true iff it is executable and if was successfully executed
    def was_executed?
      false
    end

    # Returns the number of times it was executed (completely or not)
    def runs
      0
    end

    ### Public API

    ## Singleton methods
    class << self
      # Returns a subclass or itself, according to type
      def factory(type)
        class_name = type.capitalize
        const_defined?(class_name) ? const_get(class_name) : Node
      end

      def augment(child_base_node, context, parent = nil)
        # Skip children that aren't node themselves (e.g. the `method` child of a :def node)
        return child_base_node unless child_base_node.is_a? Parser::AST::Node
        factory(child_base_node.type).create(child_base_node, context, parent)
      end

      alias_method :create, :new
    end

    # Code to add before the node for covering purposes (or `nil`)
    def prefix
    end

    # Code to add after the node for covering purposes (or `nil`)
    def suffix
    end

    # Returns true iff it changed the usual control flow (e.g. anything that raises, return, ...)
    # TODO: may not be that useful, e.g. `next`...
    def changed_control_flow?
      children_nodes.any?(&:changed_control_flow?)
    end

    def children_nodes
      children.select{|c| c.is_a? Node }
    end

    ### Internal API

    def each_node(order = :postorder, &block)
      return to_enum :each_node, order unless block_given?
      yield self unless order == :postorder
      children_nodes.each do |child|
        child.each_node(order, &block)
      end
      yield self if order == :postorder
      self
    end

    def line_cover
      return unless ex = loc.expression
      context.line_hit(ex.line - 1, runs)
      children_nodes.each(&:line_cover)
    end

    def fancy_type
      class_name = self.class.to_s.rpartition('::').last
      t = super
      t.casecmp(class_name) == 0 ? t : "#{t}[#{class_name}]"
    end

  end
end
