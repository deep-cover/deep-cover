module DeepCover
  class Node::Def < Node
    include NodeBehavior::CoverEntry
    has_children :signature, :body
  end
end
