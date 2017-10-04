module DeepCover
  class Node
    class Variable < Node
      has_child var_name: Symbol
    end
    Ivar = Lvar = Cvar = Gvar = BackRef = Variable

    # $1
    class NthRef < Node
      has_child n: Integer
      # TODO
    end
  end
end
