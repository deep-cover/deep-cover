module DeepCover
  class Node
    class Literal < Node
      include NodeBehavior::CoverEntry
    end
    Int = True = False = Str = Nil = Float = Complex = Erange = Node::Literal

    class StaticFragment < Node
      include NodeBehavior::CoverFromParent
    end
    Regopt = StaticFragment

    class Regexp < Node::Literal
      def self.factory(type)
        type == :str ? Node::StaticFragment : super
      end
    end

    class Node::Sym < Node
      include NodeBehavior::CoverEntry

      def regular_form?
        location.expression.source =~ /^(:|%s)/
      end

      # def short_hash_form?
      #   location.expression.source[-1] == ':'
      # end

      # def symbol_literal_form?
      #   !regular_form? && !short_hash_form?
      # end

      def prefix
        super if regular_form?
      end

      def suffix
        super if regular_form?
      end

      def executable?
        regular_form?
      end
    end
  end
end
