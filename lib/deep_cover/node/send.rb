module DeepCover
  class Node
    class Send < Node
      check_completion
      has_child receiver: [Node, nil]
      has_child method: Symbol
      has_extra_children arguments: Node
    end
  end
end
