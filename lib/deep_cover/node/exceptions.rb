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
    end

    class Kwbegin < Node
      include CoverWithNextInstruction

      def next_instruction
        children[0]
      end
    end

    class Rescue < Node
      include CoverWithNextInstruction

      def next_instruction
        children[0]
      end
    end

  end
end
