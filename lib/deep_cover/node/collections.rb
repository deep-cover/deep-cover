require_relative 'literals'

module DeepCover
  class Node::Array < Node
    include NodeBehavior::CoverWithNextInstruction
    include NodeBehavior::CoverEntry
    has_children rest: :elements

    Static = Node::Literal

    def self.reclassify(base_node)
      Static if base_node.location.expression.source[0] == '%'
    end
  end

  class Node::Hash < Node
    include NodeBehavior::CoverEntry
    has_children rest: :pairs
  end

  # Erange is in literals
  class Node::Irange < Node
    include NodeBehavior::CoverEntry
    has_children :from, :to
  end

  class Node::Pair < Node
    include NodeBehavior::CoverWithNextInstruction
    has_children :key, :value, next_instruction: :value
  end

  class Node::Kwsplat < Node
    include NodeBehavior::CoverWithNextInstruction
    has_children :argument
  end

  class Node::Splat < Node
    include NodeBehavior::CoverWithNextInstruction
    has_children :argument
  end
end
