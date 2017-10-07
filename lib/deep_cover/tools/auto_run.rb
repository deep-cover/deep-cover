require 'deep_cover'
require 'pry'

module DeepCover
  module AutoRun
    extend self

    def detect
      @covered_path = File.expand_path('./lib')
      Coverage.saved? @covered_path
    end

    def load
      @coverage = Coverage.load(@covered_path)
    end

    def save
      @coverage.save_trackers(@covered_path)
    end

    def after_tests
      use_at_exit = true
      if defined?(Minitest)
        puts "Registering with Minitest"
        use_at_exit = false
        Minitest.after_run { yield }
      end
      if defined?(Rspec)
        use_at_exit = false
        puts "Registering with Rspec"
        RSpec.configure do |config|
          config.after(:suite) { yield }
        end
      end
      if use_at_exit
        puts "Using at_exit"
        at_exit { yield }
      end
    end

    def run!
      detect
      load
      after_tests { save }
    end

    run!
  end
end
