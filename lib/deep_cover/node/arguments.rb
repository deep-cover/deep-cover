require_relative 'assignments'

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
      has_tracker :default
      has_child name: Symbol
      has_child default: Node, flow_entry_count: :default_tracker_hits, rewrite: '(%{default_tracker};%{node})'
      executed_loc_keys :name, :operator

      def executable?
        false
      end
    end
    Kwoptarg = Optarg

    # foo(&block)
    class Blockarg < Node
      has_child name: Symbol

      def executable?
        false
      end
    end

    class Args < Node
      has_extra_children arguments: [Arg, Optarg, Restarg, Kwarg, Kwoptarg, Kwrestarg, Blockarg, Mlhs]

      def executable?
        false
      end
    end
  end
end
