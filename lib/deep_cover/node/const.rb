module DeepCover
  class Node::Const < Node
    check_completion
    has_child scope: [Node, nil]
    has_child const_name: Symbol
  end

  class Node::Cbase < Node
    # Seems like a real pain to check properly for the leading `::`.
    # It's always clear from whatever follows though, so:
    def executable?
      false
    end
  end
end
