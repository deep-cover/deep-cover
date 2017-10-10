require_relative 'splat'

module DeepCover
  class Node
    class Array < Node
      has_extra_children elements: Node
      executed_loc_keys :begin, :end
    end

    class Pair < Node
      has_child key: Node
      has_child value: Node
      executed_loc_keys :operator
    end

    class Hash < Node
      has_extra_children elements: [Pair, Kwsplat]
      executed_loc_keys :begin, :end
    end
  end
end
