require 'deep_cover'
require 'pry'

module DeepCover
  module AutoRun
    extend self

    def detect
      raise "Can't auto run DeepCover" unless File.exists?('./lib/coverage.deep_cover')
      @covered_path = File.expand_path('./lib')
    end

    def load
      @coverage = Coverage.load(@covered_path)
    end

    def report
      puts "Lines not covered:", @coverage.report
    end

    def run!
      detect
      load
      at_exit { report }
    end
    binding.pry
    run!
  end
end
