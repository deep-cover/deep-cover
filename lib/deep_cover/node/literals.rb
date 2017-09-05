module DeepCover
  class Node
    class Literal < Node
      include NodeBehavior::CoverEntry
    end
    Int = True = False = Str = Nil = Sym = Node::Literal
  end
end
