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

      def runs
        condition.runs
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
