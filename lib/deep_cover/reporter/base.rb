# frozen_string_literal: true

module DeepCover
  module Reporter
    class Base
      attr_reader :options

      def initialize(coverage, **options)
        @coverage = coverage
        @options = options
      end

      def analysis
        @analysis ||= Coverage::Analysis.new(@coverage.covered_codes, **options)
      end
    end
  end
end
