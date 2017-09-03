module DeepCover
  class Node
    class Variables < Node
      include Node::CoverEntry
    end
    Ivar = Lvar = Cvar = Gvar = Back_ref = Variables
  end
end
