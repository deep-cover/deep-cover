module DeepCover
  module NodeBehavior
    module CoverEntry
      def prefix
        " (($_cov[#{context.nb}][#{nb*2}]+=1;"
      end

      def suffix
        '))'
      end

      def ran_entry?
        entry_runs > 0
      end

      def entry_runs
        context.cover.fetch(nb*2)
      end

      def runs
        entry_runs
      end
    end
  end
end
