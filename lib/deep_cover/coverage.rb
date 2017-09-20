require 'parser'
require 'parser/current'
require 'pry'
require 'pathname'

module DeepCover
  # A collection of CoveredCode that share a binding
  class Coverage
    attr_reader :binding

    def initialize(binding = DeepCover::GLOBAL_BINDING.dup)
      @covered_code = {}
      @binding = binding
    end

    def line_coverage(filename)
      covered_code(filename).line_coverage
    end

    def covered_code(path)
      raise 'path must be an absolute path' unless Pathname.new(path).absolute?
      @covered_code[path] ||= CoveredCode.new(path: path, binding: @binding)
    end
  end
end
