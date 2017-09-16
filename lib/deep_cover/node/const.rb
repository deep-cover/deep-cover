module DeepCover
  class Node::Const < Node
    check_completion
    has_child scope: [Node, nil]
    has_child const_name: Symbol
  end

  class Node::Cbase < Node
  end
end
