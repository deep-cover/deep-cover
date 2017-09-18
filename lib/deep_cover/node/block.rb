module DeepCover
  class Node
    class Block < Node
      has_child receiver: Node
      has_child args: Args
      has_child body: [Node, nil]

      # TODO
    end

    # &foo
    class Block_pass < Node
      has_child block: Node
      # TODO
    end
  end
end
