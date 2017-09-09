module DeepCover
  module NodeBehavior
    module CoverEntryAndExit
      include CoverEntry

      def suffix
        "#{super}.tap{$_cov[#{context.nb}][#{nb*2+1}]+=1}"
      end

      def ran_exit?
        exit_runs > 0
      end

      def exit_runs
        context.cover.fetch(nb*2+1)
      end

      def was_executed?
        ran_exit? || (ran_entry? && children_executed_before.none?(&:interrupted_control?))
      end

      def children_executed_before # Override if different
        children_nodes
      end

      def interrupted_control?
        !ran_exit? || super
      end
    end
  end
end
