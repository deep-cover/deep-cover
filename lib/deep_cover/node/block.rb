require_relative 'send'
require_relative 'keywords'

module DeepCover
  class Node
    module WithBlock
      def flow_completion_count
        parent.flow_completion_count
      end

      def execution_count
        last = children_nodes.last
        return last.flow_completion_count if last
        super
      end
    end

    class SendWithBlock < Node
      include WithBlock
      has_child receiver: [Node, nil]
      has_child method_name: Symbol
      has_extra_children arguments: Node
    end

    class SuperWithBlock < Node
      include WithBlock
      has_extra_children arguments: Node
    end

    class Block < Node
      check_completion
      has_tracker :body
      has_child call: {send: SendWithBlock, zsuper: SuperWithBlock, super: SuperWithBlock}
      has_child args: Args
      has_child body: [Node, nil],
                rewrite: '%{body_tracker};%{node}',
                flow_entry_count: :body_tracker_hits,
                local_var_level: -> { local_var_level + 1 },
                local_var_id: 0

      def executable?
        false
      end
    end

    # &foo
    class BlockPass < Node
      has_child block: Node
      # TODO
    end
  end
end
