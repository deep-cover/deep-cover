require_relative 'literals'

module DeepCover
  class Node
    class Send < Node
      check_completion
      has_child receiver: [Node, nil]
      has_child method_name: Symbol
      has_extra_children arguments: Node

      def executed_loc_keys
        :selector
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
