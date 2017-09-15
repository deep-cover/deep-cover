module DeepCover
  class Node
    class Begin < Node
      has_child expressions: Node, rest: true
    end
  end
end
