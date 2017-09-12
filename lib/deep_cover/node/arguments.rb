module DeepCover
  class Node
    class Args < Node
      has_children :arguments__rest
      def executable?
        false
      end
    end

    class Arg < Node
      def executable?
        false
      end
    end
    Kwrestarg = Kwarg = Restarg = Arg

    class Optarg < Node
      has_children :name, :default

      def executable?
        false
      end
    end
    Kwoptarg = Optarg
  end
end
