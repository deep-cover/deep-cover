require_relative 'arguments'

module DeepCover
  class Node::Def < Node
    check_completion
    has_tracker :method_call
    has_child method_name: Symbol
    has_child signature: Args
    has_child body: [Node, nil], rewrite: '%{method_call_tracker};%{node};',
      flow_entry_count: :method_call_tracker_hits
    def children_nodes_in_flow_order
      []
    end

    def executed_loc_keys
      [:keyword, :end]
    end
  end

  class Node::Defs < Node
    check_completion
    has_tracker :method_call
    has_child singleton: Node, rewrite: '(%{node})'
    has_child method_name: Symbol
    has_child signature: Args
    has_child body: [Node, nil], rewrite: '%{method_call_tracker};%{node};',
      flow_entry_count: :method_call_tracker_hits
    def children_nodes_in_flow_order
      [singleton]
    end

    def executed_loc_keys
      [:keyword, :end]
    end
  end
end
