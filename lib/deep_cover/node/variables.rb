module DeepCover
  class Node
    class Variable < Node
      has_child var_name: Symbol
    end
    Ivar = Lvar = Cvar = Gvar = Back_ref = Variable

    # $1
    class Nth_ref < Node
      has_child index: Integer
      # TODO
    end
  end
end
