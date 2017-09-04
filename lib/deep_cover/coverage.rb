require 'parser'
require 'parser/current'

module DeepCover
  class Coverage
    def initialize
      @context = {}
    end

    def require(filename)
      ctxt = context(filename) { |path| Context.new(path) }
      rewriter = Rewriter.new(ctxt)
      ast = Parser::CurrentRuby.new.parse(ctxt.buffer)
      ctxt.covered_source = rewriter.rewrite(ctxt.buffer, ast)
      ctxt.covered_ast = rewriter.root_node
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
