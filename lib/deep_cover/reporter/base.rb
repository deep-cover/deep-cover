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

      def each(&block)
        return to_enum :each unless block_given?
        @coverage.each do |covered_code|
          yield covered_code.name, covered_code
        end
        self
      end
    end
  end
end
