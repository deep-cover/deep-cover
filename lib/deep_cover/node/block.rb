module DeepCover
  class Node
    class Block < Node
      has_child receiver: Node
      has_child args: Args
      has_child body: Node

      # TODO
    end
  end
end
