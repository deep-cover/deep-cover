module DeepCover
  class Node
    class Arg < Node
      has_child name: Symbol
      def executable?
        false
      end
    end
    Kwarg = Arg

    class Restarg < Node
      has_child name: [Symbol, nil]
      def executable?
        false
      end
    end
    Kwrestarg = Restarg

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
