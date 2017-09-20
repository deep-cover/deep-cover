module DeepCover
  class Node
    class For < Node
      has_tracker :body
      has_child assignations: [Mlhs, VariableAssignment], flow_entry_count: -> { body.flow_entry_count if body }
      has_child iterable: [Node], flow_entry_count: -> { flow_entry_count }
      has_child body: [Node, nil], flow_entry_count: :body_tracker_hits,
        rewrite: '((%{body_tracker}; %{node}))'
      check_completion

      def executable?
        body
      end

      def execution_count
        iterable.flow_completion_count
      end
    end
  end
end
