module DeepCover
  module NodeBehavior
    # Will use the next instruction (defaults to first child) to decide number of runs
    # Supports next_instruction being `nil`, in which case there should be a way to
    # cover that case: define `prefix|suffix` and `runs`, or include another behavior.
    # These methods will only be called when there is no next_instruction
    #
    # Implementation detail: we `prepend` a module to interrupt prefix/suffix/runs unless
    # there is no next instruction
    #
    module CoverWithNextInstruction
      module CoverIfNeeded
        def prefix
          super unless next_instruction
        end

        def suffix
          super unless next_instruction
        end

        def runs
          next_instruction ? next_instruction.runs : super
        end
      end

      def next_instruction # Overwrite if it's not the first child
        children[0]
      end

      def self.included(base)
        base.send :prepend, CoverIfNeeded
      end
    end
  end
end
