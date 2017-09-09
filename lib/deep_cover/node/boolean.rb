module DeepCover
  class Node::Or < Node
    has_children :first, :conditional
    include NodeBehavior::CoverEntry
  end

  class Node::And < Node
    has_children :first, :conditional
    include NodeBehavior::CoverEntry
  end
end

