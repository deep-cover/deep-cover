require 'parser'
require 'parser/current'
require 'pry'
require 'pathname'

module DeepCover
  # A collection of CoveredCode
  class Coverage
    include Enumerable

    def initialize(**options)
      @covered_code = {}
      @options = options
    end

    def line_coverage(filename)
      covered_code(filename).line_coverage
    end

    def covered_code(path)
      raise 'path must be an absolute path' unless Pathname.new(path).absolute?
      @covered_code[path] ||= CoveredCode.new(path: path, **@options)
    end

    def each
      return to_enum unless block_given?
      @covered_code.each{|_path, covered_code| yield covered_code}
      self
    end
  end
end
