module DeepCover
  module NodeBehavior
    # Will use the arguments (typically the children nodes) to decide number of runs
    # In case of no children nodes there must be a way to cover that case:
    # define `prefix|suffix` and `runs`, or include another behavior.
    # These methods will only be called when there are no arguments
    #
    # Implementation detail: we `prepend` a module to interrupt prefix/suffix/runs unless
    # there are arguments
    #
    module CoverFromArguments
      module CoverIfNeeded
        def prefix
          super || raise(NotImplementedError) if arguments.empty?
        end

        def suffix
          super || raise(NotImplementedError) if arguments.empty?
        end

        def runs
          first = arguments.first
          if first
            first.runs
          else
            super
          end
        end

        def full_runs
          last = arguments.last
          if last
            last.full_runs
          else
            runs
          end
        end
      end

      def arguments # Overwrite if it's not the first child
        children_nodes
      end

      def self.included(base)
        base.send :prepend, CoverIfNeeded
      end
    end
  end
end
