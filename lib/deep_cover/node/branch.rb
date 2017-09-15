module DeepCover
  class Node
    module Branch
      def flow_completion_count
        branches.map(&:flow_completion_count).inject(0, :+)
      end

      # Define in sublasses:
      def branches
        raise NotImplementedError
      end

      # Also define runs
    end

    class TrivialBranch < Struct.new(:condition, :other_branch)
      def runs
        condition.flow_completion_count - other_branch.runs
      end
      alias_method :flow_completion_count, :runs
    end

  end
end
