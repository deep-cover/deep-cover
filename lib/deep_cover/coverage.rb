require 'parser'
require 'parser/current'
require 'pry'
require 'pathname'

module DeepCover
  class Coverage
    def initialize
      @file_coverage = {}
    end

    def line_coverage(filename)
      file_coverage(filename).line_coverage
    end

    def file_coverage(path)
      raise 'path must be an absolute path' unless Pathname.new(path).absolute?
      @file_coverage[path] ||= FileCoverage.new(path: path)
    end

    def resolve_path(filename)
      File.expand_path(filename)
    end
  end
end
