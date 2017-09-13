module DeepCover
  class Node::Def < Node
    has_children :signature, :body
  end
end
