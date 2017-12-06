# frozen_string_literal: true

require_relative 'branch'

module DeepCover
  class Node
    class If < Node
      include Branch
      has_tracker :truthy
      has_child condition: Node, rewrite: '((%{node}) && %{truthy_tracker})'
      has_child true_branch: Node,
                executed_loc_keys: -> { :else if style == :unless },
                flow_entry_count: :truthy_tracker_hits,
                is_statement: true
      has_child false_branch: Node,
                executed_loc_keys: -> { [:else, :colon] if style != :unless },
                flow_entry_count: -> { condition.flow_completion_count - truthy_tracker_hits },
                is_statement: true
      executed_loc_keys :keyword, :question

      def child_can_be_empty(child, name)
        return false if name == :condition || style == :ternary
        if (name == :true_branch) == (style == :if)
          (base_node.loc.begin || base_node.children[0].loc.expression.succ).end
        elsif has_else?
          base_node.loc.else.end.succ
        else
          true # implicit else
        end
      end

      def branches
        [true_branch, false_branch]
      end

      def execution_count
        condition.flow_completion_count
      end

      # returns on of %i[ternary if unless elsif]
      def style
        keyword = loc_hash[:keyword]
        keyword ? keyword.source.to_sym : :ternary
      end

      def has_else?
        !!base_node.loc.to_hash[:else]
      end
    end
  end
end
