module DeepCover
  class Node
    class Kwbegin < Node
      has_child instructions: Node, rest: true
    end
  end
end
