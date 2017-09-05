require "parser"

def require_relative_dir(dir_name)
  dir = File.dirname(caller.first.partition(/\.rb:\d/).first)
  Dir["#{dir}/#{dir_name}/*.rb"].each do |file|
    require file
  end
end

require_relative_dir 'deep_cover'

module DeepCover
  class << self
    def start
    end

    def require(filename)
      cover.require(filename)
    end

    def line_coverage(filename)
      cover.line_coverage(filename)
    end

    def context(filename)
      cover.context(filename)
    end

    def cover
      @cover ||= Coverage.new
    end
  end
end
