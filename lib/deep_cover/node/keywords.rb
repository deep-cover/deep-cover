require_relative 'const'

module DeepCover
  class Node
    class Kwbegin < Node
      has_extra_children instructions: Node
    end

    class Module < Node
      has_child const: Const
      has_child body: [Node, nil]
    end

    class Return < Node
      has_extra_children values: Node
      # TODO
    end
  end
end
