require_relative 'splat'

module DeepCover
  class Node
    class Array < Node
      has_extra_children elements: Node

      def executed_loc_keys
        [:begin, :end]
      end
    end

    class Pair < Node
      has_child key: Node
      has_child value: Node

      def executed_loc_keys
        :operator
      end
    end

    class Hash < Node
      has_extra_children elements: [Pair, Kwsplat]

      def executed_loc_keys
        [:begin, :end]
      end
    end
  end
end
