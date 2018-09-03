# frozen_string_literal: true

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

    class SendWithBlock < SendBase
      include WithBlock
    end

    class SuperWithBlock < Node
      include WithBlock
      has_extra_children arguments: Node
    end

    class Block < Node
      check_completion
      has_tracker :body
      has_child call: {send: SendWithBlock, zsuper: SuperWithBlock, super: SuperWithBlock, csend: Csend}
      has_child args: Args
      has_child body: Node,
                can_be_empty: -> { base_node.loc.end.begin },
                rewrite: '%{body_tracker};%{local}=nil;%{node}',
                flow_entry_count: :body_tracker_hits,
                is_statement: true
      executed_loc_keys # none

      def execution_count
        call.execution_count
      end

      def children_nodes_in_flow_order
        [call] # Similarly to a def, the body (and Args) are actually not part of the flow of this node...
      end

      alias_method :rewrite_for_completion, :rewrite
      def rewrite
        if call.is_a?(Csend)
          rewrite_for_completion.gsub('%{node}', Csend::REWRITE_SUFFIX)
        else
          rewrite_for_completion
        end
      end
    end

    # &foo
    class BlockPass < Node
      has_child block: Node
      # TODO
    end
  end
end
