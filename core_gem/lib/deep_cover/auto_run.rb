# frozen_string_literal: true

require_relative 'core_ext/exec_callbacks'
require_relative 'tools/after_tests'

module DeepCover
  module AutoRun
    class Runner
      include Tools::AfterTests
      def initialize
      end

      def run!
        after_tests { save }
        ExecCallbacks.before_exec { save }
        self
      end

      def report!(**options)
        after_tests { puts report(**options) }
        self
      end

      private

      def save
        require_relative '../deep_cover'
        Persistence.new(@covered_path).save_trackers(DeepCover::GlobalVariables.tracker_hits_per_paths)
      end

      def report(**options)
        DeepCover.coverage.report(**options)
      end
    end

    def self.run!(covered_path)
      @runners ||= {}
      @runners[covered_path] ||= Runner.new.run!
    end
  end
end
