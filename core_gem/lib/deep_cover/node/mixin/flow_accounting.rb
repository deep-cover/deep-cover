# frozen_string_literal: true

module DeepCover
  module Node::Mixin
    module FlowAccounting
      def self.included(base)
        base.has_child_handler('%{name}_flow_entry_count')
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
      # For now at least, don't return `nil`, instead return `false` in `executable?`
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
      def child_flow_entry_count(child, _name = nil)
        prev = child.previous_sibling
        if prev
          prev.flow_completion_count
        else
          flow_entry_count
        end
      end

      # Returns the counts in a hash
      def counts
        {flow_entry: flow_entry_count, flow_completion: flow_completion_count, execution: execution_count}
      end
    end
  end
end
