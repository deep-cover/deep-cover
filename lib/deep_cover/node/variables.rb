module DeepCover
  class Node
    class Variables < Node
      include NodeBehavior::CoverEntry
    end
    Ivar = Lvar = Cvar = Gvar = Back_ref = Variables

    class Lvasgn < Node
      include NodeBehavior::CoverEntryAndExit
    end
  end
end
