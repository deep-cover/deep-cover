require_relative 'const'

module DeepCover
  class Node
    class Kwbegin < Node
      has_extra_children instructions: Node
    end

    class Module < Node
      has_child const: Const
      has_child body: [Node, nil]
      # TODO
    end

    class Class < Node
      has_child const: Const
      has_child inherit: [Node, nil]
      has_child body: [Node, nil]
      # TODO
    end

    # class << foo
    class Sclass < Node
      has_child object: Node
      has_child body: [Node, nil]
      # TODO
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
