module DeepCover
  class Node::Send < Node
    include NodeBehavior::CoverEntryAndExit

    def receiver
      children.first
    end

    def method
      children.fetch(1)
    end

    def arguments
      children.drop(2)
    end
  end
end
