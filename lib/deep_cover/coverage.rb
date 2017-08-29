require 'parser'
require "unparser"

module DeepCover
  class Coverage
    def initialize
      @sources = {}
    end

    def require(filename)
      buffer = source_buffer(filename) { |path| SourceBuffer.new(path) }
      buffer.read
      buffer.ast = Parser::CurrentRuby.new.parse(buffer)
      buffer.covered_source = Rewriter.new.rewrite(buffer, buffer.ast)
      buffer.cover

      self
    end

    def coverage(filename)
      source_buffer(filename).coverage
    end

    def source_buffer(filename, &block)
      path = resolve_path(filename)
      @sources[path] ||= yield path
    end

    def resolve_path(filename)
      File.expand_path(filename)
    end
  end
end
