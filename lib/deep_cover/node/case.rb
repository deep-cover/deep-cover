require_relative 'branch'

module DeepCover
  class Node
    class WhenCondition < Node
      has_tracker :entry
      # Using && instead of ; solves a weird bug in jruby 9.1.7.0 and 9.1.9.0 (probably before too).
      # The following will only print 'test' once
      #    class EqEqEq; def ===(other); puts 'test'; end; end
      #    eqeqeq = EqEqEq.new
      #    case 1; when eqeqeq; end
      #    case 1; when (3;eqeqeq); end
      # See https://github.com/jruby/jruby/issues/4804
      # This is solved in jruby 9.2.0.0, better keep the workaround
      # for compatibility.
      has_child condition: Node, rewrite: "(((%{entry_tracker}) && %{node}))",
        flow_entry_count: :entry_tracker_hits

      def initialize(base_node, **kwargs)
        super(base_node, base_children: [base_node], **kwargs)
      end

      def flow_entry_count
        entry_tracker_hits
      end

      def flow_completion_count
        condition.flow_completion_count
      end

      def loc_hash
        condition.loc_hash
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

      def initialize(base_node, **kwargs)
        super(base_node, base_children: [base_node], **kwargs)
      end

      def flow_entry_count
        return entry_tracker_hits if body
        parent.flow_completion_count - parent.children[1...index].map(&:body_completion_count).inject(0, :+)
      end

      def loc_hash
        {else: parent.loc_hash[:else]}
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

      def executed_loc_keys
        if evaluate
          :begin
        else
          :end
        end
      end
    end
  end
end
