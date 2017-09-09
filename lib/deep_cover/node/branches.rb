module DeepCover
  class Node
    module Branch
      def runs
        full_runs
      end

      def full_runs
        full_branch_runs.inject(0, :+)
      end

      def full_branch_runs
        branches.map(&:full_runs)
      end

      def branches
        raise NotImplementedError
      end
    end

    class If < Node
      include Branch

      has_children :condition, rest: :branches

      def runs
        condition.runs
      end
    end
  end
end
