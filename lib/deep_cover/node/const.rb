module DeepCover
  class Node::Const < Node
    has_tracker :completion
    has_child scope: [Node, nil]
    has_child const_name: Symbol

    def flow_completion_count
      completion_tracker_hits
    end

    def execution_count
      return super if scope.nil?
      scope.flow_completion_count
    end

    def rewrite
      "((%{node})).tap{|v| #{completion_tracker_source}}"
    end
  end

  class Node::Cbase < Node
    # Seems like a real pain to check properly for the leading `::`.
    # It's always clear from whatever follows though, so:
    def executable?
      false
    end
  end
end
