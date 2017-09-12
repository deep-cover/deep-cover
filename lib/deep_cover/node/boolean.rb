require_relative 'branch'

module DeepCover
  class Node
    class ShortCircuit < Node
      include Branch
      has_children :first, :conditional
      has_tracker :truthy

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
        ")).tap{|v| #{truthy_tracker_source} #{self.class::TRACK_OPERATOR} v}"
      end

      def child_runs(child)
        case child.index
        when FIRST
          runs
        when CONDITIONAL
          truthy_tracker_hits
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
