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
        @nb ? context.cover.fetch(nb*2+1) : 0
      end

      def was_executed?
        ran_exit? || (ran_entry? && children_executed_before.none?(&:changed_control_flow?))
      end

      def children_executed_before # Override if different
        children_nodes
      end

      def changed_control_flow?
        !ran_exit? || super
      end
    end
  end
end
