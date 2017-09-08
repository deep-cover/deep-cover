module DeepCover
  module NodeBehavior
    module CoverWithNextInstruction
      def suffix
        ";$_cov[#{context.nb}][#{nb*2}]+=1;nil" unless next_instruction
      end

      def runs
        next_instruction ? next_instruction.runs : context.cover.fetch(nb*2)
      end

      def next_instruction # Override if it's not the first child
        children[0]
      end
    end
  end
end
