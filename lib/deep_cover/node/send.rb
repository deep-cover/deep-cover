require_relative 'literals'

module DeepCover
  class Node
    class Send < Node
      check_completion
      has_child receiver: [Node, nil]
      has_child method_name: Symbol
      has_extra_children arguments: Node
      executed_loc_keys :dot, :selector_begin, :selector_end, :operator

      def loc_hash
        base = super
        hash = { expression: base[:expression], begin: base[:begin], end: base[:end], dot: base[:dot]}
        selector = base[:selector]

        if [:[], :[]=].include?(method_name)
          hash[:selector_begin] = selector.resize(1)
          hash[:selector_end] = Parser::Source::Range.new(selector.source_buffer, selector.end_pos - 1, selector.end_pos)
        else
          hash[:selector_begin] = base[:selector]
        end

        hash
      end

      # Only need to add them to deal with ambiguous cases where a method is hidden by a local. Ex:
      #   foo 42, 'hello'  #=> Works
      #   foo (42), 'hello'  #=> Simplification of what DeepCover would generate, still works
      #   foo = 1; foo 42, 'hello'  #=> works
      #   foo = 1; foo (42), 'hello'  #=> syntax error.
      #   foo = 1; foo((42), 'hello')  #=> works
      def add_parentheses?
        # No issue when no arguments
        return if arguments.empty?
        # No ambiguity if there is a receiver
        return if receiver
        # Already has parentheses
        return if self.loc_hash[:begin]
        true
      end

      def rewriting_rules
        rules = super
        if add_parentheses?
          range = arguments.last.expression.with(begin_pos: loc_hash[:selector_begin].end_pos)
          rules << [range, '(%{node})']
        end
        rules
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
