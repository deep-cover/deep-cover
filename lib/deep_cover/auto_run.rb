# frozen_string_literal: true

require 'deep_cover'
require 'pry'

module DeepCover
  module AutoRun
    class Runner
      def initialize(covered_path)
        @covered_path = covered_path
      end

      def run!
        @coverage = load_coverage
        after_tests { save }
        self
      end

      def report!(**options)
        after_tests { puts report(**options) }
        self
      end

      private

      def load_coverage
        @not_saved = DeepCover.respond_to?(:running?) && DeepCover.running?
        if @not_saved
          DeepCover.coverage
        else
          Coverage.load(@covered_path, with_trackers: false)
        end
      end

      def save
        @coverage.save(@covered_path) if @not_saved
        @coverage.save_trackers(@covered_path)
      end

      def report(**options)
        @coverage.report(**options)
      end

      def after_tests
        use_at_exit = true
        if defined?(Minitest)
          use_at_exit = false
          Minitest.after_run { yield }
        end
        if defined?(Rspec)
          use_at_exit = false
          RSpec.configure do |config|
            config.after(:suite) { yield }
          end
        end
        if use_at_exit
          at_exit { yield }
        end
      end
    end

    def self.run!(covered_path)
      @runner ||= Runner.new(covered_path).run!
      self
    end

    def self.and_report!(**options)
      @runner.report!(**options)
    end
  end
end
