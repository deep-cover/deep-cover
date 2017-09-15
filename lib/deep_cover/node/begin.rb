module DeepCover
  class Node
    class Begin < Node
      has_extra_children expressions: Node
    end
  end
end
