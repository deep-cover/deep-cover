module DeepCover
  class Node::Const < Node
    include NodeBehavior::CoverEntryAndExit
    has_children :scope, :const_name
  end

  class Node::Cbase < Node
    # Seems like a real pain to check properly for the leading `::`.
    # It's always clear from whatever follows though, so:
    def executable?
      false
    end
  end
end
