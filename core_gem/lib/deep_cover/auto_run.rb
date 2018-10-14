# frozen_string_literal: true

require_relative 'core_ext/exec_callbacks'
require_relative 'tools/after_tests'

module DeepCover
  module AutoRun
    class Runner
      include Tools::AfterTests
      def initialize
        @saved = !(DeepCover.respond_to?(:running?) && DeepCover.running?)
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
    end

    def self.run!(covered_path)
      @runners ||= {}
      @runners[covered_path] ||= Runner.new.run!
    end
  end
end
