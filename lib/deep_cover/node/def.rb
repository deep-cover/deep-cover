require_relative 'arguments'

module DeepCover
  class Node::Def < Node
    has_tracker :method_call
    has_child method_name: Symbol
    has_child signature: Args
    has_child body: [Node, nil], rewrite: '%{method_call_tracker};%{node};',
      flow_entry_count: :method_call_tracker_hits

    alias_method :flow_completion_count, :flow_entry_count
  end

  class Node::Defs < Node
    has_child singleton: Node
    has_child method_name: Symbol
    has_child signature: Args
    has_child body: [Node, nil]
  end
end
