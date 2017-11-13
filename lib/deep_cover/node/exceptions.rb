# frozen_string_literal: true

require_relative 'variables'
require_relative 'collections'

module DeepCover
  class Node
    class Resbody < Node
      has_tracker :entered_body
      has_child exception: [Node::Array, nil]
      has_child assignment: [Lvasgn, nil], flow_entry_count: :entered_body_tracker_hits
      has_child body: Node,
                can_be_empty: -> { base_node.loc.expression.end },
                flow_entry_count: :entered_body_tracker_hits,
                is_statement: true,
                rewrite: '((%{entered_body_tracker};%{local}=nil;%{node}))'

      def is_statement
        false
      end

      def execution_count
        entered_body_tracker_hits
      end
    end

    class Rescue < Node
      has_child watched_body: Node,
                can_be_empty: -> { base_node.loc.expression.begin },
                is_statement: true
      has_extra_children resbodies: Resbody
      has_child else: Node,
                can_be_empty: -> { base_node.loc.expression.end },
                flow_entry_count: :execution_count,
                is_statement: true
      executed_loc_keys :else

      def is_statement
        false
      end

      def flow_completion_count
        resbodies.map(&:flow_completion_count).inject(0, :+) + self.else.flow_completion_count
      end

      def execution_count
        watched_body.flow_completion_count
      end

      def resbodies_flow_entry_count(child)
        prev = child.previous_sibling

        if prev.equal? watched_body
          prev.flow_entry_count - prev.flow_completion_count
        else # RESBODIES
          if prev.exception
            prev.exception.flow_completion_count - prev.execution_count
          else
            prev.flow_entry_count - prev.execution_count
          end
        end
      end
    end

    class Ensure < Node
      has_child body: Node,
                can_be_empty: -> { base_node.loc.expression.begin },
                is_statement: true
      has_child ensure: Node,
                can_be_empty: -> { base_node.loc.expression.end },
                is_statement: true,
                flow_entry_count: -> { body.flow_entry_count }

      def flow_completion_count
        body.flow_completion_count
      end
    end
  end
end
