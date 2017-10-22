require_relative 'arguments'

module DeepCover
  class Node::Def < Node
    check_completion
    has_tracker :method_call
    has_child method_name: Symbol
    has_child signature: Args
    has_child body: Node,
      rewrite: '%{method_call_tracker};nil;%{node};',
      can_be_empty: -> { base_node.loc.end.begin },
      is_statement: true,
      flow_entry_count: :method_call_tracker_hits
    executed_loc_keys :keyword, :name, :end

    def children_nodes_in_flow_order
      []
    end
  end

  class Node::Defs < Node
    check_completion
    has_tracker :method_call
    has_child singleton: Node, rewrite: '(%{node})'
    has_child method_name: Symbol
    has_child signature: Args
    has_child body: Node,
      rewrite: '%{method_call_tracker};nil;%{node};',
      can_be_empty: -> { base_node.loc.end.begin },
      is_statement: true,
      flow_entry_count: :method_call_tracker_hits
    executed_loc_keys :keyword, :name, :operator, :end

    def children_nodes_in_flow_order
      [singleton]
    end
  end
end
