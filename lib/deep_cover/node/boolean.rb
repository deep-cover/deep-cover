require_relative 'branch'

module DeepCover
  class Node
    class ShortCircuit < Node
      include Branch
      has_children :first, :conditional

      def branches
        [
          conditional,
          TrivialBranch.new(first, conditional)
        ]
      end

      def runs
        first.runs
      end
    end

    Or = And = ShortCircuit
  end
end
