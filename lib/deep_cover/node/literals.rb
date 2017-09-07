module DeepCover
  class Node
    class Literal < Node
      class StaticFragment < Node
        include NodeBehavior::CoverFromParent
      end

      include NodeBehavior::CoverEntry

      # Most literals have no children, but those that do (Dsym, Regexp, Dstring)
      # must not track those
      REMAP = {str: StaticFragment, sym: StaticFragment}
      def self.factory(type)
        REMAP[type] || super
      end
    end
    Int = True = False = Str = Nil = Float = Complex = Erange = Regexp = Dsym = Dstr = Node::Literal

    StaticSym = Regopt = Literal::StaticFragment

    class Node::Sym < Node::Literal
      def self.create(base_node, *args)
        if base_node.location.expression.source =~ /^(:|%s)/
          super
        else
          Node::StaticSym.create(base_node, *args)
        end
      end
    end
  end
end
