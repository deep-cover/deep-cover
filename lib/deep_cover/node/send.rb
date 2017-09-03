module DeepCover
  class Node::Send < Node
    include Node::CoverEntryAndExit

    def receiver
      children.first
    end

    def method
      children.fetch(1)
    end

    def arguments
      children.drop(2)
    end

    def was_called?
      ran_exit? || (ran_entry? && arguments.none?(&:changed_control_flow?))
    end
  end
end
