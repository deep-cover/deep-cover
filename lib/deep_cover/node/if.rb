module DeepCover
  class Node::If < Node
    has_children :condition, :if_true, :if_false

    def runs
      condition.runs
    end

    def full_runs
      if_true.full_runs + if_false.full_runs
    end
  end
end
