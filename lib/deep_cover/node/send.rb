require_relative 'literals'

module DeepCover
  class Node
    class Send < Node
      check_completion
      has_child receiver: [Node, nil]
      has_child method_name: Symbol
      has_extra_children arguments: Node

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

      def executed_loc_keys
        [:dot, :selector_begin, :selector_end, :operator]
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
