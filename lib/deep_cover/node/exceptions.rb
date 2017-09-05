module DeepCover
  class Node
    class Resbody < Node
      include NodeBehavior::CoverWithNextInstruction

      def exception
        children[0]
      end

      def assignment
        children[1]
      end

      def body
        children[2]
      end
      alias_method :next_instruction, :body

      def line_cover
        # Ruby doesn't cover the rescue clause itself, so skip till the body
        body.line_cover if body
      end
    end

    class Kwbegin < Node
      include NodeBehavior::CoverWithNextInstruction
    end

    class Rescue < Node
      include NodeBehavior::CoverWithNextInstruction
    end

    class Begin < Node
      include NodeBehavior::CoverWithNextInstruction
    end
  end
end
