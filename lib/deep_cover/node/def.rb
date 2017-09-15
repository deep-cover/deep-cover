module DeepCover
  class Node::Def < Node
    has_child method_name: Symbol
    has_child signature: Args
    has_child body: [Node, nil]
  end
end
