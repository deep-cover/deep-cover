require_relative 'branch'

module DeepCover
  class Node
    class When < Node
      # include Branch
      has_extra_children matches: Node
      has_child body: [Node, nil]
      # TODO
    end

    class Case < Node
      # include Branch
      has_child evaluate: [Node, nil]
      has_extra_children whens: When
      has_child else: [Node, nil]
      # TODO
    end
  end
end
