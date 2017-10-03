module DeepCover
  # By default, nodes are considered executed if they are entered.
  # Some are considered executed only if their arguments complete.
  module ExecutedAfterChildren
    def execution_count
      last = children_nodes_in_flow_order.last
      return last.flow_completion_count if last
      super
    end
  end
end
