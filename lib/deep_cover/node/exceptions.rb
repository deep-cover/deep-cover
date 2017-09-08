module DeepCover
  class Node
    class ExceptionCatchVariableAssign < Node
      include NodeBehavior::CoverFromParent
    end

    class Resbody < Node
      include NodeBehavior::CoverWithNextInstruction

      def suffix # Only called when body is nil
        ";$_cov[#{context.nb}][#{nb*2}]+=1;nil"
      end

      def runs # Only called when body is nil
        context.cover.fetch(nb*2)
      end

      def self.factory(type, child_index: )
        child_index == 1 ? ExceptionCatchVariableAssign : super
      end

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
