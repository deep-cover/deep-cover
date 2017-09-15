module DeepCover
  class Node
    Ivar = Lvar = Cvar = Gvar = Back_ref = Node

    class Lvasgn < Node
      has_children :var_name, :value

      def proper_flow_entry_count
        return super unless value
        value.flow_completion_count
      end
    end
  end
end
