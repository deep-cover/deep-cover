# frozen_string_literal: true

# This is a complete replacement for the builtin Coverage module of Ruby

module DeepCover
  module CoverageReplacement
    class << self
      def running?
        DeepCover.running?
      end

      def start
        return if running?
        DeepCover.start
        nil
      end

      def result
        r = peek_result
        DeepCover.stop
        r
      end

      def peek_result
        raise 'coverage measurement is not enabled' unless running?
        DeepCover.coverage.covered_codes.map do |covered_code|
          [covered_code.path.to_s, covered_code.line_coverage(allow_partial: false)]
        end.to_h
      end
    end
  end
end
