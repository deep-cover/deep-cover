module DeepCover
  # Base class to handle covered nodes.
  class Node
    include HasTracker
    include HasChild
    extend CheckCompletion
    attr_reader :index, :parent, :children, :base_node

    def initialize(base_node, parent: raise, index: 0, base_children: base_node.children)
      @base_node = base_node
      @parent = parent
      @index = index
      @children = augment_children(base_children)
      super()
    end

    ### High level API for coverage purposes

    # Returns an array of character numbers (in the original buffer) that
    # pertain exclusively to this node (and thus not to any children).
    def proper_range
      return [] unless location
      full_range - children_nodes.flat_map(&:full_range)
    end

    def full_range
      return [] unless location
      location.to_hash.values.map(&:to_a).inject(:+)
    end

    def [](v)
      children[v]
    end

    # Returns true iff it is executable and if was successfully executed
    def was_executed?
      # There is a rare case of non executable nodes that have important data in flow_entry_count / flow_completion_count,
      # like `if cond; end`, so make sure it's actually executable first...
      executable? && execution_count > 0
    end

    # Returns the control flow entered the node.
    # The control flow can then either complete normally or be interrupted
    #
    # Implementation: This is always the responsibility of the parent; Nodes should not override.
    def flow_entry_count
      parent.child_flow_entry_count(self)
    end

    # Returns the number of times it changed the usual control flow (e.g. raised, returned, ...)
    # Implementation: This is always deduced; Nodes should not override.
    def flow_interrupt_count
      flow_entry_count - flow_completion_count
    end

    ### These are refined by subclasses

    # Returns true iff it is executable. Keywords like `end` are not executable, but literals like `42` are executable.
    def executable?
      true
    end

    # Returns number of times the node itself was "executed". Definition of executed depends on the node.
    def execution_count
      flow_entry_count
    end

    # Returns the number of times the control flow succesfully left the node.
    # This is the responsability of the child Node, never of the parent.
    # Must be refined if the child node may have an impact on control flow (raising, branching, ...)
    def flow_completion_count
      last = children_nodes_in_flow_order.last
      return last.flow_completion_count if last
      flow_entry_count
    end

    # Returns the number of time the control flow entered this child_node.
    # This is the responsability of the Node, not of the child.
    # Must be refined if the parent node may have an impact on control flow (raising, branching, ...)
    def child_flow_entry_count(child)
      handler_value = super
      return handler_value if handler_value

      prev = child.previous_sibling
      if prev
        prev.flow_completion_count
      else
        flow_entry_count
      end
    end

    # Code to add before and after the node for covering purposes
    def rewrite
      '%{node}'
    end

    def resolve_rewrite(rule, context)
      rule ||= '%{node}'
      sources = context.tracker_sources
      rule.split('%{node}').map{|s| s % sources }
    end

    def rewrite_prefix_suffix
      parent_prefix, parent_suffix = resolve_rewrite(parent.rewrite_child(self), parent)
      prefix, suffix = resolve_rewrite(rewrite, self)
      [
        "#{prefix}#{parent_prefix}",
        "#{parent_suffix}#{suffix}"
      ]
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

    def location
      base_node.location
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

    # Must apply the result to the received array directly
    def apply_line_hits(hits_results)
      return unless ex = location && location.expression

      lineno = ex.line - 1
      hits_results[lineno] = [hits_results[lineno] || 0, flow_entry_count].max

      children_nodes.each{|c| c.apply_line_hits(hits_results) }
    end

    def fancy_type
      class_name = self.class.to_s.rpartition('::').last
      t = type.to_s
      t.casecmp(class_name) == 0 ? t : "#{t}[#{class_name}]"
    end

  end
end
