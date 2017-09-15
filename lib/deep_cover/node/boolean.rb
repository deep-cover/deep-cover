require_relative 'branch'

module DeepCover
  class Node
    class ShortCircuit < Node
      include Branch
      has_tracker :conditional
      has_child first: Node
      has_child conditional: Node, flow_entry_count: :conditional_tracker_hits

      def branches
        [
          conditional,
          TrivialBranch.new(first, conditional)
        ]
      end

      def child_prefix(child)
        return unless child.index == CONDITIONAL
        "((#{conditional_tracker_source};"
      end

      def child_suffix(child)
        return unless child.index == CONDITIONAL
        # The new value is still truthy
        "))"
      end
    end

    And = Or = ShortCircuit

  end
end
