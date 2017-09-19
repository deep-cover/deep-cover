require_relative 'const'

module DeepCover
  class Node
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
  end
end
