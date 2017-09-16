module DeepCover
  class Node
    class Splat < Node
      check_completion '*[%{node}]'
      has_child receiver: Node
    end

    class Kwsplat < Node
      check_completion '**{%{node}}'
      has_child receiver: Node
    end
  end
end
