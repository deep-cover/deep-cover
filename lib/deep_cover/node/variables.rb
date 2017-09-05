module DeepCover
  class Node
    class Variables < Node
      include NodeBehavior::CoverEntry
    end
    Ivar = Lvar = Cvar = Gvar = Back_ref = Variables
  end
end
