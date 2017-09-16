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

      # Also define flow_entry_count
    end

    class TrivialBranch < Struct.new(:condition, :other_branch)
      def flow_completion_count
        condition.flow_completion_count - other_branch.flow_entry_count
      end
    end

  end
end
