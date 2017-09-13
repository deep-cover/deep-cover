require 'backports/2.1.0/enumerable/to_h'

module DeepCover
  class AstRoot
    attr_reader :file_coverage, :nb

    def initialize(file_coverage)
      @file_coverage = file_coverage
      @nb = file_coverage.create_node_nb
    end

    def child_runs(_child)
      file_coverage.cover.fetch(nb*2)
    end

    def child_prefix(_child)
      "(($_cov[#{file_coverage.nb}][#{nb*2}] += 1;"
    end

    def child_suffix(_child)
      "))"
    end
  end
end
