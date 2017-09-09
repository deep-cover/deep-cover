module DeepCover
  class Node
    ### Static literals
    class StaticLiteral < Node
      include NodeBehavior::Static
    end
    Int = True = False = Str = Nil = Float = Complex = Erange = StaticLiteral

    ### Dynamic literals
    class Literal < Node
      class StaticFragment < Node
        include NodeBehavior::CoverFromParent
      end

      include NodeBehavior::CoverEntry
      has_children rest: :fragments

      # The static strings or symbols when building
      # must not track those
      REMAP = {str: StaticFragment, sym: StaticFragment}
      def self.factory(type, **)
        REMAP[type] || super
      end
    end
    Regexp = Dsym = Dstr = Node::Literal

    StaticSym = Regopt = Literal::StaticFragment

    class Node::Sym < Node::Literal
      def self.reclassify(base_node)
        Node::StaticSym unless base_node.location.expression.source =~ /^(:|%s)/
      end
    end
  end
end
