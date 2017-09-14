require_relative 'branch'

module DeepCover
  class Node
    class ShortCircuit < Node
      include Branch
      has_children :first, :conditional
      has_tracker :conditional

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

      def child_runs(child)
        case child.index
        when FIRST
          super
        when CONDITIONAL
          conditional_tracker_hits
        end
      end
    end

    And = Or = ShortCircuit

  end
end
