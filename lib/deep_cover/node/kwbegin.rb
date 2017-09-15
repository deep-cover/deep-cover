module DeepCover
  class Node
    class Kwbegin < Node
      has_extra_children instructions: Node
    end
  end
end
