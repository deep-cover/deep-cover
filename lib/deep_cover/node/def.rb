module DeepCover
  class Node::Def < Node
    include NodeBehavior::CoverEntryAndExit

    def children_executed_before
      []
    end
  end
end
