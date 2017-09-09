module DeepCover
  class Node
    module Branch
      def full_runs
        branches.map(&:full_runs).inject(0, :+)
      end

      # Define in sublasses:
      def branches
        raise NotImplementedError
      end

      # Also define runs
    end

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

    class TrivialBranch < Struct.new(:condition, :other_branch)
      def runs
        condition.full_runs - other_branch.runs
      end
      alias_method :full_runs, :runs
    end

  end
end
