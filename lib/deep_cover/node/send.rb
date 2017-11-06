require_relative 'literals'
require_relative 'branch'

module DeepCover
  class Node
    class SendBase < Node
      has_child receiver: [Node, nil]
      has_child message: Symbol
      has_extra_children arguments: Node
      executed_loc_keys :dot, :selector_begin, :selector_end, :operator

      def loc_hash
        hash = super.dup
        selector = hash.delete(:selector)

        # Special case for foo[bar]=baz, but not for foo.[]= bar, baz: we split selector into begin and end
        if base_node.location.dot == nil && [:[], :[]=].include?(message)
          hash[:selector_begin] = selector.resize(1)
          hash[:selector_end] = Parser::Source::Range.new(selector.source_buffer, selector.end_pos - 1, selector.end_pos)
        else
          hash.delete(:dot) if type == :safe_send # Hack. API to get a Parser::AST::Send::Map without the dot is crappy.
          hash[:selector_begin] = selector
        end

        hash
      end

      # Rules must be ordered inner-most first
      def rewriting_rules
        rules = super
        if need_parentheses?
          range = arguments.last.expression.with(begin_pos: loc_hash[:selector_begin].end_pos)
          rules.unshift [range, '(%{node})']
        end
        rules
      end

      private

      # In different circumstances, we need ().
      # Deal with ambiguous cases where a method is hidden by a local. Ex:
      #   foo 42, 'hello'  #=> Works
      #   foo (42), 'hello'  #=> Simplification of what DeepCover would generate, still works
      #   foo = 1; foo 42, 'hello'  #=> works
      #   foo = 1; foo (42), 'hello'  #=> syntax error.
      #   foo = 1; foo((42), 'hello')  #=> works
      # Deal with do/end block. Ex:
      #   x.foo 42, 43 # => ok
      #   x.foo (42), 43 # => ok
      #   x.foo ((42)), 43 # => ok
      #   x.foo 42, 43 do ; end # => ok
      #   x.foo (42), 43 do ; end # => ok
      #   x.foo ((42)), 43 do ; end # => parse error!
      def need_parentheses?
        true unless
          arguments.empty? || # No issue when no arguments
          loc_hash[:selector_end] || # No issue with foo[bar]= and such
          loc_hash[:operator] || # No issue with foo.bar=
          loc_hash[:begin] # Ok if has parentheses
      end
    end

    class Send < SendBase
      check_completion
    end

    class Csend < Node
      include Branch
      has_tracker :conditional
      has_child receiver: Node,
                rewrite: '(%{local}=%{node};%{conditional_tracker} if %{local} != nil;%{local})'

      has_child actual_send: {safe_send: Send},
                flow_entry_count: :conditional_tracker_hits

      def initialize(base_node, base_children: base_node.children, **)
        send_without_receiver = base_node.updated(:safe_send, [nil, *base_node.children.drop(1)])
        base_children = [base_children.first, send_without_receiver]
        super
      end

      executed_loc_keys :dot

      def execution_count
        receiver.flow_completion_count
      end

      def message
        actual_send.message
      end

      def branches
        [ actual_send,
          TrivialBranch.new(condition: receiver, other_branch: actual_send)
        ]
      end
    end

    class MatchWithLvasgn < Node
      check_completion
      has_child receiver: Regexp
      has_child compare_to: Node
      # TODO: test
    end
  end
end
