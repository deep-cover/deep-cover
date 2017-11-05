require_relative 'empty_body'

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

    class TrivialBranch < Node::EmptyBody
      def initialize(other_branch: raise, condition: raise, position: true)
        @condition = condition
        @other_branch = other_branch
        super(nil, parent: condition.parent, position: position)
      end

      def flow_entry_count
        @condition.flow_completion_count - @other_branch.flow_entry_count
      end
    end

  end
end
