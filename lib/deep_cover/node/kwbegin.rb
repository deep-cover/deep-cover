module DeepCover
  class Node
    class Kwbegin < Node
      def flow_completion_count
        last = children.last
        return last.flow_completion_count if last
        super
      end
    end
  end
end
