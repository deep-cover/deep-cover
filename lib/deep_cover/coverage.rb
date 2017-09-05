require 'parser'
require 'parser/current'

module DeepCover
  class Coverage
    def initialize
      @context = {}
    end

    def require(filename)
      ctxt = context(filename) { |path| Context.new(path: path) }
      ctxt.cover

      self
    end

    def naive_coverage(filename)
      context(filename).naive_coverage
    end

    def context(filename, &block)
      path = resolve_path(filename)
      @context[path] ||= yield path
    end

    def resolve_path(filename)
      File.expand_path(filename)
    end
  end
end
