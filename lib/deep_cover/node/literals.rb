require_relative 'begin'
require_relative 'variables'
module DeepCover
  class Node
    # Singletons
    class SingletonLiteral < Node
      def executed_loc_keys
        :expression
      end
    end
    True = False = Nil = SingletonLiteral

    # Atoms
    def self.atom(type)
      ::Class.new(Node) do
        def executed_loc_keys
          :expression
        end
      end.has_child value: type
    end
    Sym = atom(::Symbol)
    Int = atom(::Integer)
    Float = atom(::Float)
    Complex = atom(::Complex)
    Rational = atom(::Rational)
    class Regopt < Node
      has_extra_children options: [::Symbol]

      def executed_loc_keys
        :expression
      end
    end

    class Str < Node
      has_child value: ::String

      def executed_loc_keys
        [:expression, :heredoc_body, :heredoc_end]
      end
    end

    # Di-atomic
    class Range < Node
      has_child from: Node
      has_child to: Node
    end
    Erange = Irange = Range

    # Dynamic
    def self.has_evaluated_segments
      has_extra_children constituents: [Str, Begin, Ivar, Cvar, Gvar, Dstr]
    end
    class DynamicLiteral < Node
    end
    Dsym = Dstr = DynamicLiteral
    DynamicLiteral.has_evaluated_segments

    class Regexp < Node
      has_evaluated_segments
      has_child option: Regopt
    end

    class Xstr < Node
      check_completion
      has_evaluated_segments
    end
  end
end
