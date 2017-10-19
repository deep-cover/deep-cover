require "parser"
require_relative "deep_cover/misc"
module DeepCover

  Misc.require_relative_dir 'deep_cover/parser_ext'
  Misc.require_relative_dir 'deep_cover'

  class << self
    def start
      require_relative 'deep_cover/core_ext/require_overrides'
    end

    def line_coverage(filename)
      cover.line_coverage(filename)
    end

    def covered_code(filename)
      cover.covered_code(filename)
    end

    def cover
      @cover ||= Coverage.new
    end

    def custom_requirer
      @custom_requirer ||= CustomRequirer.new
    end
  end
end
DeepCover::GLOBAL_BINDING = binding
