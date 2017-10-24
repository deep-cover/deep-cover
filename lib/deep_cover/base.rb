module DeepCover
  module Base
    def start
      return if @started
      if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
        # No issues with autoload in jruby, so no need to override it!
      else
        require_relative 'core_ext/autoload_overrides'
        autoload_tracker.initialize_autoloaded_paths
      end
      require_relative 'core_ext/require_overrides'
      @started = true
    end

    def line_coverage(filename)
      coverage.line_coverage(filename)
    end

    def covered_code(filename)
      coverage.covered_code(filename)
    end

    def coverage
      @coverage ||= Coverage.new
    end

    def custom_requirer
      @custom_requirer ||= CustomRequirer.new
    end

    def autoload_tracker
      @autoload_tracker ||= AutoloadTracker.new
    end
  end
end
