require_relative "const"

module DeepCover
  class Node
    class VariableAssignment < Node
      has_child var_name: Symbol
      has_child value: [Node, nil]

      def executed_loc_keys
        [:name, :operator]
      end

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

    # a, b = ...
    class Masgn < Node
      class BackwardsNode < Node
        include BackwardsStrategy
      end

      class SelfReceiver < BackwardsNode
        def executed_loc_keys
          :expression
        end
      end

      class ConstantCbase < BackwardsNode
      end

      class DynamicReceiverWrap < Node
        include Wrapper
        has_tracker :entry
        has_child actual_receiver: Node
        def rewrite
          '(%{local} = (%{node});%{entry_tracker}; %{local}=%{local})'
        end
        alias_method :flow_entry_count, :entry_tracker_hits
      end

      class Setter < Node
        include BackwardsStrategy
        has_child receiver: {self: SelfReceiver, Parser::AST::Node => DynamicReceiverWrap}
        has_child method_name: Symbol
        has_child arg: [Node, nil] # When method is :[]=

        def loc_hash
          base = super
          if method_name == :[]=
            selector = base[:selector]
            {
                expression: base[:expression],
                selector_begin: selector.resize(1),
                # The = is implicit, so only backtrack the end by one
                selector_end: Parser::Source::Range.new(selector.source_buffer, selector.end_pos - 1, selector.end_pos),
            }
          else
            {
                dot: base[:dot],
                expression: base[:expression],
                selector_begin: base[:selector],
                selector_end: nil#,
            }
          end
        end

        def executed_loc_keys
          [:dot, :selector_begin, :selector_end]
        end
      end

      class ConstantScopeWrapper < Node
        include Wrapper
        has_tracker :entry
        has_child actual_node: Node

        def rewrite
          '(%{entry_tracker};%{node})'
        end

        def flow_entry_count
          entry_tracker_hits
        end
      end

      class ConstantAssignment < Node
        include BackwardsStrategy
        has_child scope: [nil], remap: {cbase: ConstantCbase, Parser::AST::Node => ConstantScopeWrapper}
        has_child constant_name: Symbol

        def execution_count
          scope ? scope.flow_completion_count : super
        end
      end

      class VariableAssignment < Node
        include BackwardsStrategy
        has_child var_name: Symbol
      end

      BASE_MAP = {
        cvasgn: VariableAssignment, gvasgn: VariableAssignment,
        ivasgn: VariableAssignment, lvasgn: VariableAssignment,
        casgn: ConstantAssignment,
        send: Setter,
      }
      class Splat < Node
        include BackwardsStrategy
        has_child rest_arg: BASE_MAP

        def executed_loc_keys
          :operator
        end
      end

      class LeftSide < Node
        include BackwardsStrategy
        has_extra_children receivers: {
          splat: Splat,
          mlhs: LeftSide,
          **BASE_MAP,
        }
        def flow_completion_count
          parent.flow_completion_count
        end

        def executed_loc_keys
          [:begin, :end]
        end
      end

      check_completion

      has_child left: {mlhs: LeftSide}
      has_child value: Node

      def execution_count
        value.flow_completion_count
      end

      def executed_loc_keys
        :operator
      end

      def children_nodes_in_flow_order
        [value, left]
      end
    end

    class VariableOperatorAssign < Node
      has_child var_name: Symbol
    end

    class ConstantOperatorAssign < Node
      has_child scope: [Node, nil]
      has_child const_name: Symbol
      def execution_count
        flow_completion_count
      end
    end

    class SendOperatorAssign < Node
      has_child receiver: [Node, nil]
      has_child method_name: Symbol
      has_extra_children arguments: Node

      def executed_loc_keys
        [:dot, :selector]
      end
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

      def executed_loc_keys
        :operator
      end
    end

    # foo ||= bar, foo &&= base
    class BooleanAssignment < Node
      check_completion
      has_tracker :long_branch
      has_child receiver: {
        lvasgn: VariableOperatorAssign, ivasgn: VariableOperatorAssign,
        cvasgn: VariableOperatorAssign, gvasgn: VariableOperatorAssign,
        casgn: ConstantOperatorAssign,
        send: SendOperatorAssign,
      }
      has_child value: Node, rewrite: '(%{long_branch_tracker};%{node})', flow_entry_count: :long_branch_tracker_hits

      def execution_count
        flow_completion_count
      end

      def executed_loc_keys
        :operator
      end
    end

    OrAsgn = AndAsgn = BooleanAssignment
  end
end
