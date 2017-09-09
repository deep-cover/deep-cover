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

    class TrivialBranch < Struct.new(:condition, :other_branch)
      def runs
        condition.full_runs - other_branch.runs
      end
      alias_method :full_runs, :runs
    end

  end
end
