module DeepCover
  class Node
    class Literal < Node
      class StaticFragment < Node
        include NodeBehavior::CoverFromParent
      end

      include NodeBehavior::CoverEntry

      # Most literals have no children, but those that do (Dsym, Regexp, Dstring)
      # must not track those
      def self.factory(type)
        type == :str ? StaticFragment : super
      end
    end
    Int = True = False = Str = Nil = Float = Complex = Erange = Regexp = Dsym = Dstr = Node::Literal

    Regopt = Literal::StaticFragment

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
