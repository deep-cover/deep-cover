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

      def self.factory(type, **)
        # The bits of strings when building dynamic symbols, strings
        # or regexp are parsed as :str, but we don't want to track those.
        type == :str ? StaticFragment : super
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
