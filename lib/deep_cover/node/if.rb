require_relative 'branch'

module DeepCover
  class Node
    class If < Node
      include Branch
      has_child condition: Node
      has_child true_branch: [Node, nil]
      has_child false_branch: [Node, nil]

      def branches
        [
          true_branch || TrivialBranch.new(condition, false_branch),
          false_branch || TrivialBranch.new(condition, true_branch)
        ]
      end

      def child_prefix(child)
        return unless child.index == CONDITION
        "(("
      end

      def child_suffix(child)
        return unless child.index == CONDITION
        # The new value is still truthy
        ")) && $_cov[#{file_coverage.nb}][#{nb*2}] += 1"
      end

      def child_flow_entry_count(child)
        case child.index
        when CONDITION
          super
        when TRUE_BRANCH
          file_coverage.cover.fetch(nb*2)
        when FALSE_BRANCH
          condition.flow_completion_count - file_coverage.cover.fetch(nb*2)
        end
      end

      def flow_completion_count
        executable? ? super : condition.flow_completion_count
      end

      # If both branches are nil, mark as non-executable
      def executable?
        true_branch || false_branch
      end
    end
  end
end
