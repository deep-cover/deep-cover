module DeepCover
  # Base class to handle covered nodes.
  class Node < Parser::AST::Node
    attr_reader :context, :nb, :parent

    def initialize(base_node, context, parent = nil)
      @context = context
      augmented_children = base_node.children.map.with_index { |child, child_index| self.class.augment(child, context, self, child_index) }
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

    # Returns true iff it is executable and if was successfully executed
    def was_executed?
      runs > 0
    end

    # Returns the number of times it changed the usual control flow (e.g. raised, returned, ...)
    def interrupts
      runs - full_runs
    end

    ### These are refined by subclasses

    # Returns true iff it is executable. Keywords like `end` are not executable, but literals like `42` are executable.
    def executable?
      true
    end

    # Returns the number of times it was executed (completely or not)
    def runs
      0
    end

    # Returns the number of times it was fully ran
    def full_runs
      runs
    end

    # Code to add before the node for covering purposes (or `nil`)
    def prefix
    end

    # Code to add after the node for covering purposes (or `nil`)
    def suffix
    end


    ### Singleton methods
    class << self

      ### These are refined by subclasses

      # Returns a subclass or the base Node, according to type
      def factory(type, **)
        class_name = type.capitalize
        const_defined?(class_name) ? const_get(class_name) : Node
      end

      # Override if a particular class associated for a child must
      # be changed. `nil` is interpreted the same as `self`.
      def reclassify(base_node)
      end

      ### Public API

      # Augment creates a covered node from the child_base_node.
      # It gives both the parent class and the child class a chance
      # to decide the class of the child with `factory` and `reclassify`
      # respectively.
      def augment(child_base_node, context, parent = nil, child_index = 0)
        # Skip children that aren't node themselves (e.g. the `method` child of a :def node)
        return child_base_node unless child_base_node.is_a? Parser::AST::Node
        klass = factory(child_base_node.type, child_index: child_index)
        klass = klass.reclassify(child_base_node) || klass
        klass.new(child_base_node, context, parent)
      end

    end

    ### Public API

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
