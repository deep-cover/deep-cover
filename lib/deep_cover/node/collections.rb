require_relative 'literals'

module DeepCover
  class Node::Array < Node
    include NodeBehavior::CoverEntry

    Static = Node::Literal

    def self.reclassify(base_node)
      Static if base_node.location.expression.source[0] == '%'
    end
  end

  class Node::Hash < Node
    include NodeBehavior::CoverEntry
  end

  # Erange is in literals
  class Node::Irange < Node
    include NodeBehavior::CoverEntry
  end

  class Node::Pair < Node
    include NodeBehavior::CoverWithNextInstruction

    def value
      children[1]
    end

    def next_instruction
      value
    end
  end

  class Node::Kwsplat < Node
    include NodeBehavior::CoverWithNextInstruction
  end

  class Node::Splat < Node
    include NodeBehavior::CoverWithNextInstruction
  end
end
