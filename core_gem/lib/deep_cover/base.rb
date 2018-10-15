# frozen_string_literal: true

module DeepCover
  module Base
    def running?
      @started ||= false # rubocop:disable Naming/MemoizedInstanceVariableName [#5648]
    end

    def start
      return if running?
      if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
        # Autoload is not supported in JRuby. We currently need to use binding_of_caller
        # and that is not available in JRuby. An extension may be able to replace this requirement.
        # require_relative 'core_ext/autoload_overrides'
        # AutoloadOverride.active = true
        require_relative 'core_ext/load_overrides'
        require_relative 'core_ext/require_overrides'
        LoadOverride.active = RequireOverride.active = true
      elsif RUBY_VERSION >= '2.3.0'
        require_relative 'core_ext/instruction_sequence_load_iseq'
      else
        require_relative 'core_ext/autoload_overrides'
        require_relative 'core_ext/load_overrides'
        require_relative 'core_ext/require_overrides'
        AutoloadOverride.active = LoadOverride.active = RequireOverride.active = true
        autoload_tracker.initialize_autoloaded_paths { |mod, name, path| mod.autoload_without_deep_cover(name, path) }
      end

      config # actualize configuration
      @lookup_paths = nil
      @started = true
    end

    def stop
      if defined? AutoloadOverride
        AutoloadOverride.active = false
        autoload_tracker.remove_interceptors { |mod, name, path| mod.autoload_without_deep_cover(name, path) }
      end
      RequireOverride.active = false if defined? RequireOverride

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
        @lookup_paths = nil
      when :tracker_global
        raise NotImplementedError, "Changing DeepCover's tracker global after starting coverage is not supported" if running?
        @coverage = nil
      end
    end

    def reset
      stop if running?
      @coverage = @custom_requirer = @autoload_tracker = @lookup_paths = nil
      config.reset
      self
    end

    def coverage
      @coverage ||= Coverage.new
    end

    def lookup_paths
      return @lookup_paths if @lookup_paths
      lookup_paths = config.paths || Dir.getwd
      lookup_paths = Array(lookup_paths).map { |p| File.expand_path(p) }
      lookup_paths = ['/'] if lookup_paths.include?('/')
      @lookup_paths = lookup_paths
    end

    def within_lookup_paths?(path)
      lookup_paths.any? { |lookup_path| path.start_with?(lookup_path) }
    end

    def custom_requirer
      @custom_requirer ||= CustomRequirer.new
    end

    def autoload_tracker
      @autoload_tracker ||= AutoloadTracker.new
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
