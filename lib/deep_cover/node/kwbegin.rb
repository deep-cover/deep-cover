module DeepCover
  class Node
    class Kwbegin < Node
      def full_runs
        last = children.last
        return last.full_runs if last
        super
      end
    end
  end
end
