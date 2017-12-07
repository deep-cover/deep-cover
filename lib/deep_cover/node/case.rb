# frozen_string_literal: true

require_relative 'branch'

module DeepCover
  class Node
    class WhenCondition < Node
      include Wrapper
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
      has_child condition: Node, rewrite: '(((%{entry_tracker}) && %{node}))',
                flow_entry_count: :entry_tracker_hits
      executed_loc_keys []

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

    class WhenSplatCondition < Node
      has_tracker :entry
      check_completion inner: '(%{entry_tracker};[%{node}])', outer: '*%{node}'
      has_child receiver: Node

      def flow_entry_count
        entry_tracker_hits
      end
    end

    class When < Node
      has_tracker :body_entry
      has_extra_children matches: {splat: WhenSplatCondition, Parser::AST::Node => WhenCondition}
      has_child body: Node,
                can_be_empty: -> {
                                if (after_then = base_node.loc.begin)
                                  after_then.end
                                else
                                  base_node.loc.expression.end.succ
                                end
                              },
                rewrite: '%{body_entry_tracker};%{local}=nil;%{node}',
                is_statement: true,
                flow_entry_count: :body_entry_tracker_hits

      def flow_entry_count
        matches.first.flow_entry_count
      end

      def execution_count
        matches.first.flow_completion_count
      end

      def flow_completion_count
        body.flow_completion_count + next_sibling.flow_entry_count
      end
    end

    class Case < Node
      include Branch
      has_tracker :else_entry
      has_child evaluate: [Node, nil]
      has_extra_children whens: When
      has_child else: Node,
                can_be_empty: -> { base_node.loc.end.begin },
                rewrite: -> { "#{'else;' unless has_else?}((%{else_entry_tracker};%{local}=nil;%{node}))" },
                executed_loc_keys: [:else],
                is_statement: true,
                flow_entry_count: :else_entry_tracker_hits

      executed_loc_keys :begin, :keyword

      def branches
        whens.map(&:body) << self.else
      end

      def branches_summary(of = branches)
        texts = []
        n = of.size
        if of.include? self.else
          texts << "#{'implicit ' unless has_else?}else"
          n -= 1
        end
        texts.unshift "#{n} when clause#{'s' if n > 1}" if n > 0
        texts.join(' and ')
      end

      def execution_count
        return evaluate.flow_completion_count if evaluate
        flow_entry_count
      end

      def has_else?
        !!base_node.loc.to_hash[:else]
      end
    end
  end
end
