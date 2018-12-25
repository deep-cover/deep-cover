# frozen_string_literal: true

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
          (receiver && !loc_hash[:dot]) || # No issue with foo + bar
          loc_hash[:begin] # Ok if has parentheses
      end
    end

    class Send < SendBase
      check_completion
    end

    class CsendInnerSend < SendBase
      has_tracker :completion
      include ExecutedAfterChildren

      def has_block?
        parent.has_block?
      end

      def rewrite
        # All the rest of the rewriting logic is in Csend
        '%{node});%{completion_tracker};' unless has_block?
      end

      def flow_completion_count
        return parent.parent.flow_completion_count if has_block?
        completion_tracker_hits
      end

      def loc_hash
        # This is only a partial Send, the receiver param and the dot are actually handled by the parent Csend.
        h = super.dup
        h[:expression] = h[:expression].with(begin_pos: h[:selector_begin].begin_pos)
        h
      end
    end

    class Csend < Node
      # The overall rewriting goal is this:
      #    temp = *receiver*;
      #    if nil != temp
      #      TRACK_my_NOT_NIL
      #      temp = (temp&.*actual_send*{block})
      #      TRACK_actual_send_COMPLETION
      #      temp
      #    end
      # This is split across the children and the CsendInnerSend
      include Branch
      has_tracker :not_nil
      has_child receiver: Node,
                rewrite: '(%{local}=%{node};if nil != %{local};%{not_nil_tracker};%{local}=(%{local}'
      REWRITE_SUFFIX_IN_BLOCK = '%{node});%{local};end)'

      has_child actual_send: {safe_send: CsendInnerSend},
                flow_entry_count: :not_nil_tracker_hits

      def initialize(base_node, base_children: base_node.children, **)
        send_without_receiver = base_node.updated(:safe_send, [nil, *base_node.children.drop(1)])
        base_children = [base_children.first, send_without_receiver]
        super
      end

      executed_loc_keys :dot

      extend Forwardable
      def_delegators :actual_send, :message, :arguments

      def has_block?
        parent.is_a?(Block) && parent.child_index_to_name(index) == :call
      end

      def rewrite
        '%{node};%{local};end)' unless has_block?
      end

      def execution_count
        receiver.flow_completion_count
      end

      def branches
        [TrivialBranch.new(condition: receiver, other_branch: actual_send),
         actual_send,
        ]
      end

      def branches_summary(of_branches)
        of_branches.map do |jump|
          jump == actual_send ? 'safe send' : 'nil shortcut'
        end.join(' and ')
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
