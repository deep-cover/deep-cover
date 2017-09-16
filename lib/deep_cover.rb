require "parser"
require 'active_support/core_ext/module/delegation'

def require_relative_dir(dir_name)
  dir = File.dirname(caller.first.partition(/\.rb:\d/).first)
  Dir["#{dir}/#{dir_name}/*.rb"].sort.each do |file|
    require file
  end
end

require_relative_dir 'deep_cover'

module DeepCover
  class << self
    def start
    end

    def line_coverage(filename)
      cover.line_coverage(filename)
    end

    def covered_code(filename)
      cover.covered_code(filename)
    end

    def cover
      @cover ||= Coverage.new
    end
  end
end
