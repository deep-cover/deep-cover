module DeepCover
  class Node
    class ExceptionCatchVariableAssign < Node
      include NodeBehavior::CoverFromParent
    end

    class Resbody < Node
      include NodeBehavior::CoverWithNextInstruction
      has_children :exception, :assignment, :body, next_instruction: :body

      def suffix # Only called when body is nil
        ";$_cov[#{context.nb}][#{nb*2}]+=1;nil"
      end

      def runs # Only called when body is nil
        context.cover.fetch(nb*2)
      end

      def self.factory(type, child_index: raise)
        child_index == ASSIGNMENT ? ExceptionCatchVariableAssign : super
      end


      def line_cover
        # Ruby doesn't cover the rescue clause itself, so skip till the body
        body.line_cover if body
      end
    end

    class Kwbegin < Node
      has_children rest: :instructions

      include NodeBehavior::CoverWithNextInstruction
      include NodeBehavior::CoverEntry

      def next_instruction
        n = children.first
        n if n && n.type != :rescue
      end
    end

    class Rescue < Node
      include NodeBehavior::CoverWithNextInstruction
      has_children :body, rest: :rescue_bodies

    end

    class Begin < Node
      has_children rest: :instructions
      include NodeBehavior::CoverWithNextInstruction
    end
  end
end
