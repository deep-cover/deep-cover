module DeepCover
  class Node::Const < Node
    has_children :scope, :const_name

    def full_runs
      file_coverage.cover.fetch(nb*2)
    end

    def proper_runs
      return super if scope.nil?
      scope.full_runs
    end

    def prefix
      "(("
    end

    def suffix
      ")).tap{|v| $_cov[#{file_coverage.nb}][#{nb*2}] += 1}"
    end
  end

  class Node::Cbase < Node
    # Seems like a real pain to check properly for the leading `::`.
    # It's always clear from whatever follows though, so:
    def executable?
      false
    end
  end
end
