require "parser"
require_relative "deep_cover/misc"
module DeepCover

  Misc.require_relative_dir 'deep_cover/parser_ext'
  Misc.require_relative_dir 'deep_cover', except: %w[auto_run]

  class << self
    def start
      return if @started
      if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
        # No issues with autoload in jruby, so no need to override it!
      else
        require_relative 'deep_cover/core_ext/autoload_overrides'
        autoload_tracker.initialize_autoloaded_paths
      end
      require_relative 'deep_cover/core_ext/require_overrides'
      @started = true
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

    def autoload_tracker
      @autoload_tracker ||= AutoloadTracker.new
    end
  end
end
DeepCover::GLOBAL_BINDING = binding
