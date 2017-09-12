require_relative 'branch'

module DeepCover
  class Node
    class ShortCircuit < Node
      include Branch
      has_children :first, :conditional

      def branches
        [
          conditional,
          TrivialBranch.new(first, conditional)
        ]
      end

      def child_prefix(child)
        return unless child.index == FIRST
        "(("
      end

      def child_suffix(child)
        return unless child.index == FIRST
        # The new value is still truthy
        ")).tap{|v| $_cov[#{context.nb}][#{nb*2}] += 1 #{self.class::TRACK_OPERATOR} v}"
      end

      def child_runs(child)
        case child.index
        when FIRST
          runs
        when CONDITIONAL
          context.cover.fetch(nb*2)
        end
      end
    end

    class And < ShortCircuit
      TRACK_OPERATOR = :if
    end

    class Or < ShortCircuit
      TRACK_OPERATOR = :unless
    end
  end
end
