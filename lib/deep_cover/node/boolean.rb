require_relative 'branch'

module DeepCover
  class Node
    class ShortCircuit < Node
      include Branch
      has_tracker :conditional
      has_child first: Node
      has_child conditional: Node, flow_entry_count: :conditional_tracker_hits,
        rewrite: '((%{conditional_tracker};%{node}))'

      def branches
        [
          conditional,
          TrivialBranch.new(first, conditional)
        ]
      end
    end

    And = Or = ShortCircuit

    # foo ||= bar
    class Or_asgn < Node
      has_child receiver: Node
      has_child value: Node
      # TODO
    end

  end
end
