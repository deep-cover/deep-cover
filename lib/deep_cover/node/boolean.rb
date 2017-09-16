require_relative 'branch'

module DeepCover
  class Node
    class ShortCircuit < Node
      include Branch
      has_tracker :conditional
      has_child first: Node
      has_child conditional: Node, flow_entry_count: :conditional_tracker_hits,
        rewrite: -> { "((#{conditional_tracker_source};%{node}))" }

      def branches
        [
          conditional,
          TrivialBranch.new(first, conditional)
        ]
      end
    end

    And = Or = ShortCircuit

  end
end
