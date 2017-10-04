module DeepCover
  class Node
    class For < Node
      has_tracker :body
      has_child assignments: [Mlhs, VariableAssignment], flow_entry_count: -> { body.flow_entry_count if body }
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

    class Until < Node
      has_tracker :body
      has_child condition: Node, rewrite: '((%{node})) || (%{body_tracker};false)'
      has_child body: [Node, nil], flow_entry_count: :body_tracker_hits
      check_completion

      def executable?
        body
      end

      def execution_count
        # TODO: while this distringuishes correctly 0 vs >0, the number return is often too high
        condition.flow_completion_count
      end
    end

    class UntilPost < Node
      has_tracker :body
      has_child condition: Node, rewrite: '((%{node})) || (%{body_tracker};false)'
      has_child body: Kwbegin, flow_entry_count: -> { body_tracker_hits + parent.flow_entry_count }
      check_completion

      def execution_count
        # TODO: while this distringuishes correctly 0 vs >0, the number return is often too high
        body.flow_completion_count
      end
      # TODO: test
    end

    class While < Node
      has_tracker :body
      has_child condition: Node, rewrite: '((%{node})) && %{body_tracker}'
      has_child body: [Node, nil], flow_entry_count: :body_tracker_hits
      check_completion

      def executable?
        body
      end

      def execution_count
        # TODO: while this distringuishes correctly 0 vs >0, the number return is often too high
        condition.flow_completion_count
      end
    end

    class WhilePost < Node
      has_tracker :body
      has_child condition: Node, rewrite: '((%{node})) && %{body_tracker}'
      has_child body: Kwbegin, flow_entry_count: -> { body_tracker_hits + parent.flow_entry_count }
      check_completion

      def execution_count
        # TODO: while this distringuishes correctly 0 vs >0, the number return is often too high
        body.flow_completion_count
      end
      # TODO: test
    end
  end
end
