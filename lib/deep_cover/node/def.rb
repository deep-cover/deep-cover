module DeepCover
  class Node::Def < Node
    has_children :method_name, :signature, :body
  end
end
