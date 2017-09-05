module DeepCover
  class Node::Def < Node
    include NodeBehavior::CoverEntryAndExit
  end
end
