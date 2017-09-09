module DeepCover
  class Node::Send < Node
    include NodeBehavior::CoverEntryAndExit
    has_children :receiver, :method, rest: :arguments
  end
end
