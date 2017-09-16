module DeepCover
  class Node
    class Variable < Node
      has_child var_name: Symbol
    end
    Ivar = Lvar = Cvar = Gvar = Back_ref = Variable

    class Lvasgn < Node
      has_child var_name: Symbol
      has_child value: [Node, nil]

      def execution_count
        return super unless value
        value.flow_completion_count
      end
    end
  end
end
