module DeepCover
  class Node
    class Collection < Node
      has_extra_children elements: Node
    end
    Array = Hash = Collection

    class Pair < Node
      has_child key: Node
      has_child value: Node
    end
  end
end
