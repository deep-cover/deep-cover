require_relative 'literals'

module DeepCover
  class Node
    class MethodName < Node
      has_child name: Symbol

      def initialize(name, parent: raise, **kwargs)
        super(parent, **kwargs, parent: parent, base_children: [name])
      end

      def loc_hash
        # Expression is used in the rewriting
        # if selector_end is present, then this won't be needed
        {expression: parent.loc_hash[:selector_begin]}
      end

      def executable?
        false
      end
    end

    class Send < Node
      check_completion
      has_child receiver: [Node, nil]
      has_child method_name_wrapper: {Symbol => MethodName}, rewrite: :add_opening_parentheses
      has_extra_children arguments: Node, rewrite: :add_closing_parentheses
      executed_loc_keys :dot, :selector_begin, :selector_end, :operator

      def method_name
        method_name_wrapper.name
      end

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
      #   raise TypeError, 'hello'  #=> Works
      #   raise (TypeError), 'hello'  #=> Simplification of what DeepCover generates, still works
      #   raise = 1; raise TypeError, 'hello'  #=> works
      #   raise = 1; raise (TypeError), 'hello'  #=> syntax error.
      #   raise = 1; raise((TypeError), 'hello'0  #=> works
      def add_parentheses?
        return if arguments.empty?
        # No ambiguity if there is a receiver
        return if receiver
        # Already has parentheses
        return if self.loc_hash[:begin]
        true
      end

      def add_opening_parentheses
        return unless add_parentheses?
        "%{node}("
      end

      def add_closing_parentheses(child)
        return unless add_parentheses?
        return unless child.index == children.size - 1
        "%{node})"
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
