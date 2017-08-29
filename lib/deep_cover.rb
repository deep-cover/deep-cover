require "parser"

require "deep_cover/version"
require "deep_cover/node"
require "deep_cover/rewriter"
require "deep_cover/source_buffer"
require "deep_cover/coverage"

module DeepCover
  class << self
    def start
    end

    def require(filename)
      cover.require(filename)
    end

    def coverage(filename)
      cover.coverage(filename)
    end

    def buffer(filename)
      cover.source_buffer(filename)
    end

    def cover
      @cover ||= Coverage.new
    end
  end
end
