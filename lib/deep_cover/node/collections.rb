require_relative 'splat'

module DeepCover
  class Node
    class Array < Node
      has_extra_children elements: Node
    end

    class Pair < Node
      has_child key: Node
      has_child value: Node
    end

    class Hash < Node
      has_extra_children elements: [Pair, Kwsplat]
    end
  end
end
