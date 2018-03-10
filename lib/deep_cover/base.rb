# frozen_string_literal: true

module DeepCover
  module Base
    def running?
      @started ||= false # rubocop:disable Naming/MemoizedInstanceVariableName [#5648]
    end

    def start
      return if running?
      if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
        # Autoloaded files are not supported on jruby. We need to use binding_of_caller
        # And that appears to be unavailable in jruby.
      else
        require_relative 'core_ext/autoload_overrides'
        AutoloadOverride.active = true
      end
      require_relative 'core_ext/require_overrides'
      RequireOverride.active = true
      config # actualize configuration
      @started = true
    end

    def stop
      require_relative 'core_ext/require_overrides'
      AutoloadOverride.active = false if defined? AutoloadOverride
      RequireOverride.active = false
      @started = false
    end

    def line_coverage(filename)
      coverage.line_coverage(handle_relative_filename(filename), **config.to_h)
    end

    def covered_code(filename)
      coverage.covered_code(handle_relative_filename(filename))
    end

    def cover(paths: nil)
      if paths
        prev = config.paths
        config.paths(paths)
      end
      start
      yield
    ensure
      stop
      config.paths(prev) if paths
    end

    def config_changed(what)
      case what
      when :paths
        warn "Changing DeepCover's paths after starting coverage is highly discouraged" if running?
        @custom_requirer = nil
      when :tracker_global
        raise NotImplementedError, "Changing DeepCover's tracker global after starting coverage is not supported" if running?
        @coverage = nil
      end
    end

    def reset
      stop if running?
      @coverage = @custom_requirer = nil
      config.reset
      self
    end

    def coverage
      @coverage ||= Coverage.new(tracker_global: config.tracker_global)
    end

    def custom_requirer
      @custom_requirer ||= CustomRequirer.new(lookup_paths: config.paths)
    end

    private

    def handle_relative_filename(filename)
      unless Pathname.new(filename).absolute?
        relative_to = File.dirname(caller(2..2).first.partition(/\.rb:\d/).first)
        filename = File.absolute_path(filename, relative_to)
      end
      filename += '.rb' unless filename =~ /\.rb$/
      filename
    end
  end
end
