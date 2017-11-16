# frozen_string_literal: true

module DeepCover
  module Base
    def start
      return if @started
      if defined?(RUBY_ENGINE) && RUBY_ENGINE == 'jruby'
        # No issues with autoload in jruby, so no need to override it!
      else
        require_relative 'core_ext/autoload_overrides'
        AutoloadOverride.active = true
        autoload_tracker.initialize_autoloaded_paths
      end
      require_relative 'core_ext/require_overrides'
      RequireOverride.active = true
      @started = true
    end

    def stop
      AutoloadOverride.active = false if defined? AutoloadOverride
      RequireOverride.active = false
      @started = false
    end

    def line_coverage(filename)
      coverage.line_coverage(handle_relative_filename(filename), **config)
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
      if what == :paths
        warn "Changing DeepCover's paths after starting coverage is highly discouraged" if @started
        @custom_requirer = nil
      end
    end

    def coverage
      @coverage ||= Coverage.new
    end

    def custom_requirer
      @custom_requirer ||= CustomRequirer.new(lookup_paths: config.paths)
    end

    def autoload_tracker
      @autoload_tracker ||= AutoloadTracker.new
    end

    def handle_relative_filename(filename)
      unless Pathname.new(filename).absolute?
        relative_to = File.dirname(caller(2..2).first.partition(/\.rb:\d/).first)
        filename = File.absolute_path(filename, relative_to)
      end
      filename += '.rb' unless filename =~ /\.rb$/
      filename
    end

    def parser
      Parser::CurrentRuby.new.tap do |parser|
        parser.diagnostics.all_errors_are_fatal = true
        parser.diagnostics.ignore_warnings      = true
      end
    end
  end
end
