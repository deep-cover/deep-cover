module DeepCover
  class Node
    ### Static literals
    class StaticLiteral < Node
      include NodeBehavior::Static
    end
    Int = True = False = Str = Nil = Float = Complex = Erange = StaticLiteral

    ### Dynamic literals

    # Dynamic literals are complicated because the parsed AST can be an arbitrarily
    # complicated tree of :dstr, :str, :begin, as well as :ivar, :cvar & :gvar
    # The :begin are within #{} and easily tracked, the rest are not and are
    # remapped to Literal::StaticFragment.

    module WithinStringFactory
      def factory(type, **)
        # The bits of strings when building dynamic symbols, strings
        # or regexp are parsed as :str, but we don't want to track those.
        case type
        when :begin
          super
        when :dstr
          InnerDstr
        else Literal::StaticFragment
        end
      end
    end

    class InnerDstr < Node
      extend WithinStringFactory
      has_children rest: :fragments

      def runs
        if p = previous_sibbling
          p.full_runs
        else
          parent.runs
        end
      end

      def full_runs
        children.last.full_runs
      end
    end

    class Literal < Node
      include NodeBehavior::CoverEntry
      extend WithinStringFactory
      has_children rest: :fragments

      def full_runs
        return runs unless last = children_nodes.last
        last.full_runs
      end
    end
    Regexp = Dsym = Dstr = Node::Literal

    class Literal::StaticFragment < Node
      def runs
        if p = previous_sibbling
          p.full_runs
        else
          parent.runs
        end
      end

      def full_runs
        runs
      end
    end
    StaticSym = Regopt = Literal::StaticFragment

    class Node::Sym < Node::Literal
      def self.reclassify(base_node)
        Node::StaticSym unless base_node.location.expression.source =~ /^(:|%s)/
      end
    end
  end
end
