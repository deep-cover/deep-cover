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

      def flow_completion_count
        file_coverage.cover.fetch(nb*2)
      end

      def execution_count
        last = children_nodes.last
        return last.flow_completion_count if last
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

      def flow_completion_count
        file_coverage.cover.fetch(nb*2)
      end

      def execution_count
        last = children_nodes.last
        return last.flow_completion_count if last
        super
      end
    end
  end
end
