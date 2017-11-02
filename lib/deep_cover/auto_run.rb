require 'deep_cover'
require 'pry'

module DeepCover
  module AutoRun
    class Runner
      def initialize(covered_path)
        @covered_path = covered_path
      end

      def run!
        detect
        load
        after_tests { save }
      end

      private
      def detect
        Coverage.saved? @covered_path
      end

      def load
        @coverage = Coverage.load(@covered_path, with_trackers: false)
      end

      def save
        @coverage.save_trackers(@covered_path)
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
      @already_setup ||= false # Avoid ruby warning
      Runner.new(covered_path).run! unless @already_setup
      @already_setup = true
    end
  end
end
