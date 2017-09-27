require_relative 'branch'

module DeepCover
  class Node
    class WhenCondition < Node
      has_tracker :entry
      has_child condition: Node, rewrite: "((%{entry_tracker};%{node}))",
        flow_entry_count: :entry_tracker_hits

      def augment_children
        # Augment the @base_node again, but there won't be a remap this time.
        # This way, WhenCondition is inserted between the When and the condition.
        super([@base_node])
      end

      def flow_entry_count
        entry_tracker_hits
      end

      def flow_completion_count
        condition.flow_completion_count
      end
    end

    class When < Node
      # include Branch
      has_tracker :body_entry
      has_extra_children matches: { Parser::AST::Node => WhenCondition }
      has_child body: [Node, nil], rewrite: "%{body_entry_tracker};%{node}",
        flow_entry_count: :body_entry_tracker_hits

      def rewrite
        "%{node};%{body_entry_tracker}" unless body
      end

      def flow_entry_count
        matches.first.flow_entry_count
      end

      def execution_count
        matches.first.flow_completion_count
      end

      def flow_completion_count
        body_completion_count + next_sibling.flow_entry_count
      end

      def body_completion_count
        body ? body.flow_completion_count : body_entry_tracker_hits
      end
    end

    class CaseElse < Node
      has_tracker :entry
      has_child body: [Node, nil], rewrite: "((%{entry_tracker};%{node}))",
                flow_entry_count: :entry_tracker_hits

      def augment_children
        if @base_node
          # Augment the @base_node again, but there won't be a remap this time.
          # This way, CaseElse is inserted between the When and the condition.
          super([@base_node])
        else
          []
        end
      end

      def flow_entry_count
        return entry_tracker_hits if body
        parent.flow_completion_count - parent.children[1...index].map(&:body_completion_count).inject(0, :+)
      end

      def location
        Parser::Source::Map.new(parent.location.else)
      end
    end

    class Case < Node
      # include Branch
      check_completion
      has_child evaluate: [Node, nil]
      has_extra_children whens: When
      has_child else: { NilClass => CaseElse, Parser::AST::Node => CaseElse }

      def execution_count
        return evaluate.flow_completion_count if evaluate
        flow_entry_count
      end
    end
  end
end
