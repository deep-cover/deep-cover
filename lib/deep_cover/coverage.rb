require 'parser'
require 'parser/current'

module DeepCover
  class Coverage
    def initialize
      @context = {}
    end

    def require(filename)
      ctxt = context(filename) { |path| Context.new(path) }
      ctxt.ast = Parser::CurrentRuby.new.parse(ctxt.buffer)
      ctxt.covered_source = Rewriter.new(ctxt).rewrite(ctxt.buffer, ctxt.ast)
      ctxt.cover

      self
    end

    def coverage(filename)
      context(filename).coverage
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
