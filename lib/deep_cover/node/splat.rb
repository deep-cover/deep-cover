module DeepCover
  class Node
    class Splat < Node
      has_children :receiver

      def prefix
        "*["
      end

      def suffix
        "].tap{$_cov[#{file_coverage.nb}][#{nb*2}] += 1}"
      end

      def full_runs
        file_coverage.cover.fetch(nb*2)
      end

      def proper_runs
        last = children_nodes.last
        return last.full_runs if last
        super
      end
    end

    class Kwsplat < Node
      has_children :receiver

      def prefix
        "**{"
      end

      def suffix
        "}.tap{$_cov[#{file_coverage.nb}][#{nb*2}] += 1}"
      end

      def full_runs
        file_coverage.cover.fetch(nb*2)
      end

      def proper_runs
        last = children_nodes.last
        return last.full_runs if last
        super
      end
    end
  end
end
