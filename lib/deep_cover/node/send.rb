require_relative 'literals'

module DeepCover
  class Node
    class Send < Node
      check_completion
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
          hash[:selector_begin] = selector
        end

        hash
      end

      def rewriting_rules
        rules = super
        if need_parentheses?
          range = arguments.last.expression.with(begin_pos: loc_hash[:selector_begin].end_pos)
          rules << [range, '(%{node})']
        end
        rules
      end

      private

      # Only need to add them to deal with ambiguous cases where a method is hidden by a local. Ex:
      #   foo 42, 'hello'  #=> Works
      #   foo (42), 'hello'  #=> Simplification of what DeepCover would generate, still works
      #   foo = 1; foo 42, 'hello'  #=> works
      #   foo = 1; foo (42), 'hello'  #=> syntax error.
      #   foo = 1; foo((42), 'hello')  #=> works
      def need_parentheses?
        true unless
          arguments.empty? || # No issue when no arguments
          receiver || # No ambiguity if there is a receiver
          loc_hash[:begin] # Ok if has parentheses
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
