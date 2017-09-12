require_relative 'branch'

module DeepCover
  class Node
    class If < Node
      include Branch
      has_children :condition, :true_branch, :false_branch

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
        ")) && $_cov[#{context.nb}][#{nb*2}] += 1"
      end

      def child_runs(child)
        case child.index
        when CONDITION
          super
        when TRUE_BRANCH
          context.cover.fetch(nb*2)
        when FALSE_BRANCH
          condition.full_runs - context.cover.fetch(nb*2)
        end
      end

      def full_runs
        executable? ? super : condition.full_runs
      end

      # If both branches are nil, mark as non-executable
      def executable?
        true_branch || false_branch
      end
    end
  end
end
