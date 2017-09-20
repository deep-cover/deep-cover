require_relative "const"

module DeepCover
  class Node
    class VariableAssignment < Node
      has_child var_name: Symbol
      has_child value: [Node, nil]

      def execution_count
        return super unless value
        value.flow_completion_count
      end
    end
    Cvasgn = Gvasgn = Ivasgn = Lvasgn = VariableAssignment

    class Casgn < Node
      has_child cbase: [Cbase, Const, nil]
      has_child var_name: Symbol
      has_child value: [Node, nil]

      def execution_count
        return super unless value
        value.flow_completion_count
      end
    end

    class Mlhs < Node
      has_extra_children being_set: Node
      # TODO
    end

    # a, b = ...
    class Masgn < Node
      has_child left: Mlhs
      has_child value: Node
      # TODO
    end

    # foo += bar
    class Op_asgn < Node
      has_child receiver: Node
      has_child operator: Symbol
      has_child value: Node
      # TODO
    end
  end
end
