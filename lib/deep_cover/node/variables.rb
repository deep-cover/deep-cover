module DeepCover
  class Node
    class Variable < Node
      has_child var_name: Symbol
    end
    Ivar = Lvar = Cvar = Gvar = Back_ref = Variable
  end
end
