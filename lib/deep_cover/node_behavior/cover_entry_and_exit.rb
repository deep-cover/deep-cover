module DeepCover
  module NodeBehavior
    module CoverEntryAndExit
      include CoverEntry

      def suffix
        "#{super}.tap{$_cov[#{context.nb}][#{nb*2+1}]+=1}"
      end

      def full_runs
        context.cover.fetch(nb*2+1)
      end

      def runs
        super - children_executed_before.map(&:interrupts).inject(0, :+)
      end

      def children_executed_before # Override if different
        children_nodes
      end
    end
  end
end
