module DeepCover
  class Node
    Ivar = Lvar = Cvar = Gvar = Back_ref = Node

    class Lvasgn < Node
      has_children :var_name, :value

      def proper_runs
        return super unless value
        value.full_runs
      end
    end
  end
end
