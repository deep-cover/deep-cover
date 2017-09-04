module DeepCover
  class Node
    class Arguments < Node
      def callable?
        false
      end
    end
    Args = Arg = Optarg = Restarg = Kwarg = Kwoptarg = Kwrestarg = Arguments
  end
end
