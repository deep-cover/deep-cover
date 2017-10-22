require_relative 'branch'

module DeepCover
  class Node
    class Else < Node
      include Wrapper
      has_child body: [Node, nil],
                is_statement: true

      def is_statement
        false
      end

      def loc_hash
        {else: parent.loc_hash[:else], colon: parent.loc_hash[:colon], expression: body && body.loc_hash[:expression] }
      end

      def executed_loc_keys
        if loc_hash[:else]
          if loc_hash[:else].source == 'else'
            :else
          else
            # elsif will be handled by the child body
            nil
          end
        else
          :colon
        end
      end
    end

    class If < Node
      include Branch
      has_tracker :truthy
      has_child condition: Node, rewrite: '((%{node}) && %{truthy_tracker})'
      has_child true_branch: [Node, nil],
                flow_entry_count: :truthy_tracker_hits,
                remap: :remap_branch,
                is_statement: true
      has_child false_branch: [Node, nil],
                flow_entry_count: -> { condition.flow_completion_count - truthy_tracker_hits },
                remap: :remap_branch,
                is_statement: true
      executed_loc_keys :keyword, :question

      def remap_branch(child, child_name)
        is_unless = style == :unless
        Else if child_name == :true_branch && is_unless || child_name == :false_branch && !is_unless
      end

      def branches
        [
          true_branch || TrivialBranch.new(condition, false_branch),
          false_branch || TrivialBranch.new(condition, true_branch)
        ]
      end

      def execution_count
        condition.flow_completion_count
      end

      # returns on of %i[ternary if unless elsif]
      def style
        keyword = loc_hash[:keyword]
        keyword ? keyword.source.to_sym : :ternary
      end
    end
  end
end
