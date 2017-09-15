module DeepCover
  class Node::Const < Node
    has_children :scope, :const_name

    def flow_completion_count
      file_coverage.cover.fetch(nb*2)
    end

    def execution_count
      return super if scope.nil?
      scope.flow_completion_count
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
