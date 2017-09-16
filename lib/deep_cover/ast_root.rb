require 'backports/2.1.0/enumerable/to_h'
require_relative 'has_tracker'

module DeepCover
  class AstRoot
    include HasTracker

    has_tracker :root
    attr_reader :file_coverage, :main

    def initialize(child_ast, file_coverage)
      @file_coverage = file_coverage
      @main = Node.augment(child_ast, file_coverage, self)
      super()
    end

    def child_flow_entry_count(_child)
      root_tracker_hits
    end

    def child_prefix(_child)
      "((#{root_tracker_source};"
    end

    def child_suffix(_child)
      "))"
    end
  end
end
