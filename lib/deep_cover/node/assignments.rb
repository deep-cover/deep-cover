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

    module BackwardsStrategy
      # Instead of assuming our parent tracks our entry and we are responsible
      # for tracking our completion, we go the other way and assume our parent
      # tracks our completion and we are responsible for our entry.
      def flow_completion_count
        if (s = next_sibling)
          s.flow_entry_count
        else
          parent.flow_completion_count
        end
      end

      def flow_entry_count
        if (first_child = children_nodes.first)
          first_child.flow_entry_count
        else
          flow_completion_count
        end
      end
    end

    class MasgnSetter < Node
      include BackwardsStrategy
      has_tracker :entry
      has_child receiver: Node,
                rewrite: '(%{node}).tap{%{entry_tracker}}',
                flow_entry_count: :entry_tracker_hits
      has_child method_name: Symbol
      has_child arg: [Node, nil] # When method is :[]=

      alias_method :flow_entry_count, :entry_tracker_hits
    end

    class MasgnVariableAssignment < Node
      include BackwardsStrategy
      has_child var_name: Symbol
    end

    MASGN_BASE_MAP = {
      cvasgn: MasgnVariableAssignment, gvasgn: MasgnVariableAssignment,
      ivasgn: MasgnVariableAssignment, lvasgn: MasgnVariableAssignment,
      send: MasgnSetter,
    }
    class MasgnSplat < Node
      include BackwardsStrategy
      has_child rest_arg: MASGN_BASE_MAP
    end

    class MasgnLeftSide < Node
      include BackwardsStrategy
      has_extra_children receivers: {
        splat: MasgnSplat,
        mlhs: MasgnLeftSide,
        **MASGN_BASE_MAP,
      }
      def flow_completion_count
        parent.flow_completion_count
      end
    end

    # a, b = ...
    class Masgn < Node
      check_completion

      has_child left: {mlhs: MasgnLeftSide}
      has_child value: Node

      def execution_count
        value.flow_completion_count
      end

      def children_nodes_in_flow_order
        [value, left]
      end
    end

    class VariableOperatorAssign < Node
      has_child var_name: Symbol
    end

    class SendOperatorAssign < Node
      has_child receiver: [Node, nil]
      has_child method_name: Symbol
      has_extra_children arguments: Node
    end

    # foo += bar
    class OpAsgn < Node
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

    OrAsgn = AndAsgn = BooleanAssignment
  end
end
