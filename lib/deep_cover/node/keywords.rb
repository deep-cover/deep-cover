require_relative 'variables'
require_relative 'literals'

module DeepCover
  class Node
    class Kwbegin < Node
      has_extra_children instructions: Node
    end

    class Return < Node
      has_extra_children values: Node
      # TODO
    end

    class Super < Node
      check_completion
      has_extra_children arguments: Node
      # TODO
    end
    Zsuper = Super # Zsuper is super with no parenthesis (same arguments as caller)

    class Yield < Node
      has_extra_children arguments: Node
      # TODO
    end

    class Break < Node
      has_extra_children arguments: Node
      # TODO Anything special needed for the arguments?

      def flow_completion_count
        0
      end
    end

    class Next < Node
      has_extra_children arguments: Node
      # TODO Anything special needed for the arguments?

      def flow_completion_count
        0
      end
    end

    class Alias < Node
      check_completion
      has_child alias: [Sym, Dsym, Gvar, Back_ref]
      has_child original: [Sym, Dsym, Gvar, Back_ref]
      # TODO: test
    end

    class NeverEvaluated < Node
      has_extra_children whatever: [:any], remap: {Parser::AST::Node => NeverEvaluated}

      def executable?
        false
      end
    end

    class Defined < Node
      has_child expression: {Parser::AST::Node => NeverEvaluated}
      # TODO: test
    end

    class Undef < Node
      check_completion
      has_extra_children arguments: [Sym, Dsym]
      # TODO: test
    end
  end
end
