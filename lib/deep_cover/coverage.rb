require 'parser'
require 'parser/current'
require 'pry'

module DeepCover
  class Coverage
    def initialize
      @file_coverage = {}
    end

    def require(filename)
      file_cov = file_coverage(filename) { |path| FileCoverage.new(path: path) }
      file_cov.cover

      self
    end

    def line_coverage(filename)
      file_coverage(filename).line_coverage
    end

    def file_coverage(filename, &block)
      path = resolve_path(filename)
      @file_coverage[path] ||= yield path
    end

    def resolve_path(filename)
      File.expand_path(filename)
    end
  end
end
