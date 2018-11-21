# frozen_string_literal: true

# This is a complete replacement for the builtin Coverage module of Ruby

module DeepCover
  module CoverageReplacement
    OLD_COVERAGE_SENTINEL = Object.new
    ALL_COVERAGES = {lines: true, branches: true, methods: true}.freeze

    class << self
      def running?
        DeepCover.running?
      end

      def start(targets = OLD_COVERAGE_SENTINEL)
        if targets == OLD_COVERAGE_SENTINEL
          # Do nothing
        elsif targets == :all
          targets = ALL_COVERAGES
        else
          targets = targets.to_hash.slice(*ALL_COVERAGES.keys).select { |_, v| v }
          targets = targets.map { |k, v| [k, !!v] }.to_h
          if targets.empty?
            raise 'no measuring target is specified' if RUBY_VERSION.start_with?('2.5')
            targets = OLD_COVERAGE_SENTINEL
          end
        end

        if DeepCover.running?
          raise 'cannot change the measuring target during coverage measurement' if @started_args != targets
          return
        end

        @started_args = targets

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
        if @started_args == OLD_COVERAGE_SENTINEL
          DeepCover.coverage.covered_codes.map do |covered_code|
            [covered_code.path.to_s, covered_code.line_coverage(allow_partial: false)]
          end.to_h
        else
          DeepCover.coverage.covered_codes.map do |covered_code|
            cov = {}
            cov[:branches] = DeepCover::Analyser::Ruby25LikeBranch.new(covered_code).results if @started_args[:branches]
            cov[:lines] = covered_code.line_coverage(allow_partial: false) if @started_args[:lines]
            cov[:methods] = {} if @started_args[:methods]
            [covered_code.path.to_s, cov]
          end.to_h
        end
      end
    end
  end
end
