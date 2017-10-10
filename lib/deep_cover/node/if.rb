require_relative 'branch'

module DeepCover
  class Node
    class Else < Node
      include Wrapper
      has_child body: [Node, nil]

      def loc_hash
        {else: parent.loc_hash[:else], colon: parent.loc_hash[:colon]}
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
      has_child true_branch: [Node, nil], flow_entry_count: :truthy_tracker_hits
      has_child else_branch: [Node, nil], flow_entry_count: -> { condition.flow_completion_count - truthy_tracker_hits },
                remap: Else
      executed_loc_keys :keyword, :question

      def self.new(base_node, **kwargs)
        locs = base_node.location.to_hash
        if locs[:keyword] && locs[:keyword].source == 'unless'
          Unless.new(base_node, **kwargs)
        else
          super
        end
      end

      def branches
        [
          true_branch || TrivialBranch.new(condition, else_branch),
          else_branch
        ]
      end

      def execution_count
        condition.flow_completion_count
      end
    end

    class Unless < Node
      include Branch
      has_tracker :truthy
      has_child condition: Node, rewrite: '((%{node}) && %{truthy_tracker})'
      has_child false_branch: [Node, nil], flow_entry_count: -> { condition.flow_completion_count - truthy_tracker_hits }
      has_child else_branch: [Node, nil], flow_entry_count: :truthy_tracker_hits,
                remap: Else
      executed_loc_keys :keyword

      def initialize(base_node, base_children: base_node.children, **kwargs)
        super(base_node, base_children: base_children.values_at(0, 2, 1), **kwargs)
      end

      def branches
        [
            false_branch || TrivialBranch.new(condition, else_branch),
            else_branch
        ]
      end

      def execution_count
        condition.flow_completion_count
      end
    end
  end
end
