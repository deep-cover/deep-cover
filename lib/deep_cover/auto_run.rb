# frozen_string_literal: true

module DeepCover
  module AutoRun
    class Runner
      def initialize(covered_path)
        @covered_path = covered_path
        @saved = !(DeepCover.respond_to?(:running?) && DeepCover.running?)
      end

      def run!
        after_tests { save }
        self
      end

      def report!(**options)
        after_tests { puts report(**options) }
        self
      end

      private

      def saved?
        @saved
      end

      def coverage
        @coverage ||= if saved?
                        Coverage.load(@covered_path, with_trackers: false)
                      else
                        DeepCover.coverage
                      end
      end

      def save
        require_relative '../deep_cover'
        coverage.save(@covered_path) unless saved?
        coverage.save_trackers(@covered_path)
      end

      def report(**options)
        coverage.report(**options)
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
      @runners ||= {}
      @runners[covered_path] ||= Runner.new(covered_path).run!
    end
  end
end
