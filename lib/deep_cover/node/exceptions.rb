module DeepCover
  class Node
    module CoverWithNextInstruction
      def suffix
        ";$_cov[#{context.nb}][#{nb*2}]+=1;nil" unless next_instruction
      end

      def was_executed?
        runs > 0
      end

      def runs
        next_instruction ? next_instruction.runs : context.cover.fetch(nb*2)
      end

      def next_instruction # Override if it's not the first child
        children[0]
      end
    end

    class Resbody < Node
      include CoverWithNextInstruction

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
      include CoverWithNextInstruction
    end

    class Rescue < Node
      include CoverWithNextInstruction
    end

    class Begin < Node
      include CoverWithNextInstruction
    end
  end
end
