module DeepCover
  class Node
    class Kwbegin < Node
      has_extra_children instructions: Node
    end

    class Return < Node
      has_extra_children values: Node
      # TODO
    end

    class Super < Node
      check_completion
      has_extra_children arguments: Node
      # TODO
    end
    Zsuper = Super # Zsuper is super with no parenthesis (same arguments as caller)

    class Yield < Node
      has_extra_children arguments: Node
      # TODO
    end

    class Next < Node
      has_extra_children arguments: Node
      # TODO
    end
  end
end
