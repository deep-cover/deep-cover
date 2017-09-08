module DeepCover
  module NodeBehavior
    module CoverWithNextInstruction
      def prefix
        super unless next_instruction
      end

      def suffix
        super unless next_instruction
      end

      def runs
        next_instruction ? next_instruction.runs : super
      end

      def next_instruction # Override if it's not the first child
        children[0]
      end
    end
  end
end
