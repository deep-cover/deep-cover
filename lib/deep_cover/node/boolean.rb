module DeepCover
  class Node::Or < Node
    include NodeBehavior::CoverEntry
  end

  class Node::And < Node
    include NodeBehavior::CoverEntry
  end
end

