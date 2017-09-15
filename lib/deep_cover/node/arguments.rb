module DeepCover
  class Node
    class Arg < Node
      def executable?
        false
      end
    end
    Kwrestarg = Kwarg = Restarg = Arg

    class Optarg < Node
      has_child name: Symbol
      has_child default: Node

      def executable?
        false
      end
    end
    Kwoptarg = Optarg

    class Args < Node
      has_child arguments: [Arg, Optarg, Restarg, Kwarg, Kwoptarg, Kwrestarg], rest: true
      def executable?
        false
      end
    end
  end
end
