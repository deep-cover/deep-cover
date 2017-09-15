require 'backports/2.1.0/enumerable/to_h'
require_relative 'has_tracker'

module DeepCover
  class AstRoot
    module FreezingIsPainful
      def assign_properties
      end
    end
    include FreezingIsPainful
    include HasTracker

    has_tracker :root
    attr_reader :file_coverage, :nb

    def initialize(file_coverage)
      @file_coverage = file_coverage
      assign_properties
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
