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

    class VariableOperatorAssign < Node
      has_child var_name: Symbol
    end

    class SendOperatorAssign < Node
      has_child receiver: [Node, nil]
      has_child method: Symbol
      has_extra_children arguments: Node
    end

    # foo += bar
    class Op_asgn < Node
      check_completion
      has_tracker :reader
      has_child receiver: {
        lvasgn: VariableOperatorAssign, ivasgn: VariableOperatorAssign,
        cvasgn: VariableOperatorAssign, gvasgn: VariableOperatorAssign,
        casgn: Casgn, # TODO
        send: SendOperatorAssign,
      }
      has_child operator: Symbol
      has_child value: Node, rewrite: '(%{reader_tracker};%{node})', flow_entry_count: :reader_tracker_hits
      def execution_count
        flow_completion_count
      end
    end

    # foo ||= bar, foo &&= base
    class BooleanAssignment < Node
      check_completion
      has_tracker :long_branch
      has_child receiver: {
        lvasgn: VariableOperatorAssign, ivasgn: VariableOperatorAssign,
        cvasgn: VariableOperatorAssign, gvasgn: VariableOperatorAssign,
        casgn: Casgn, # TODO
        send: SendOperatorAssign,
      }
      has_child value: Node, rewrite: '(%{long_branch_tracker};%{node})', flow_entry_count: :long_branch_tracker_hits

      def execution_count
        flow_completion_count
      end
    end

    Or_asgn = And_asgn = BooleanAssignment
  end
end
