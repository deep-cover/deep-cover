# frozen_string_literal: true

# This is a complete replacement for the builtin Coverage module of Ruby

module DeepCover
  module CoverageReplacement
    class << self
      def start
        @started = true
        DeepCover.start
        DeepCover.coverage.reset
      end

      def result
        raise 'coverage measurement is not enabled' unless @started
        @started = false
        peek_result
      end

      def peek_result
        results = DeepCover.coverage.covered_codes.map do |covered_code|
          [covered_code.path, covered_code.line_coverage(allow_partial: false)]
        end
        Hash[results]
      end
    end
  end
end
