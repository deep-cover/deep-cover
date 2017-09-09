module DeepCover
  class Node
    module Branch
      def full_runs
        branches.map(&:full_runs).inject(0, :+)
      end

      def branches
        raise NotImplementedError
      end
    end

    class If < Node
      include Branch
      has_children :condition, :true_branch, :false_branch
      attr_reader :branches

      def assign_properties(*)
        @branches = [
          true_branch || DeducedNilBranch.new(condition, false_branch),
          false_branch || DeducedNilBranch.new(condition, true_branch)
        ]
        super
      end

      def runs
        condition.runs
      end

      def full_runs
        executable? ? super : condition.full_runs
      end

      # If both branches are nil, mark as non-executable
      def executable?
        true_branch || false_branch
      end
    end

    class DeducedNilBranch < Struct.new(:condition, :other_branch)
      def runs
        condition.full_runs - other_branch.runs
      end
      alias_method :full_runs, :runs
    end

  end
end
