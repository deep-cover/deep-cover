# frozen_string_literal: true

module DeepCover
  module Base
    def running?
      @started ||= false # rubocop:disable Naming/MemoizedInstanceVariableName [#5648]
    end

    def start
      return if running?
      if RUBY_VERSION >= '2.3.0' && RUBY_PLATFORM != 'java'
        require_relative 'core_ext/instruction_sequence_load_iseq'
      else
        require_relative 'core_ext/autoload_overrides'
        require_relative 'core_ext/load_overrides'
        require_relative 'core_ext/require_overrides'
        AutoloadOverride.active = LoadOverride.active = RequireOverride.active = true
        autoload_tracker.initialize_autoloaded_paths { |mod, name, path| mod.autoload_without_deep_cover(name, path) }
      end

      config # actualize configuration
      @lookup_globs = @all_tracked_file_paths = nil
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

    def delete_trackers
      persistence.delete_trackers
    end

    def line_coverage(filename)
      filename = handle_relative_filename(filename)
      return unless coverage.covered_code?(filename)
      coverage.line_coverage(filename, **config.to_h)
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
        @lookup_globs = @all_tracked_file_paths = nil
      when :excluded_paths
        warn "Changing DeepCover's excluded_paths after starting coverage is highly discouraged" if running?
        @all_tracked_file_paths = nil
      when :tracker_global
        raise NotImplementedError, "Changing DeepCover's tracker global after starting coverage is not supported" if running?
        @coverage = nil
      end
    end

    def reset
      stop if running?
      @coverage = @custom_requirer = @autoload_tracker = @lookup_globs = @all_tracked_file_paths = nil
      config.reset
      self
    end

    def coverage
      @coverage ||= Coverage.new
    end

    def lookup_exclusion
      @lookup_exclusion ||= Regexp.union(*
        config.exclude_paths.map { |x| Tools.to_regexp(x) })
    end

    def lookup_globs
      return @lookup_globs if defined?(@lookup_globs) && @lookup_globs
      paths = Array(config.paths || :auto_detect).dup
      paths.concat(auto_detected_paths) if paths.delete(:auto_detect)

      paths = paths.map { |p| File.expand_path(p) }
      paths = ['/'] if paths.include?('/')
      globs = paths.map! do |path|
        if File.directory?(path)
          # File.join is needed to avoid //**/*.rb
          File.join(path, '**/*.rb')
        else
          # Either a single file's path, a glob, or a path that doesn't exists
          path
        end
      end
      @lookup_globs = globs
    end

    # Auto detects path that we want to cover. This is used when :auto_detect is in the config.paths.
    # If the results aren't what you expect, then specify the paths yourself.
    # We want this to work for most project's struture:
    # * Single gems: just a gem directly in the top-level
    # * Multi gems: contains multiple gems, each in a dir of the top-level dir (the rails gem does that)
    # * Hybrid gems: a gem in the top-level dir and one in sub-dirs (the deep-cover gem does that)
    # * Rails application
    #
    # For gems and Rails application, normally, everything to check coverage for is in lib/, and app/.
    # For other projects, we go for every directories except test/ spec/ bin/ exe/.
    #
    # If the current dir has a .gemspec file, we consider it a "root".
    # In addition, if any sub-dir of the current dir (not recursive) has a .gemspec file, we also consider them as "roots"
    # If the current dir looks like a Rails application, add it as a "root"
    # For each "roots", the "tracked dirs" will be "#{root}/app" and "#{root}/lib"
    #
    # If no "tracked dirs" exist, fallback to everything in current directory except each of test/ spec/ bin/ exe/.
    def auto_detected_paths
      # When taking over, just go for everything
      return ['.'] if DeepCover.const_defined?('TAKEOVER_IS_ON') && DeepCover::TAKEOVER_IS_ON

      require_relative 'tools/looks_like_rails_project'

      gemspec_paths = Dir['./*.gemspec'] + Dir['./*/*.gemspec']
      root_paths = gemspec_paths.map!(&File.method(:dirname))
      root_paths.uniq!
      root_paths << '.' if !root_paths.include?('.') && Tools::LooksLikeRailsProject.looks_like_rails_project?('.')

      tracked_paths = root_paths.flat_map { |p| [File.join(p, 'app'), File.join(p, 'lib')] }
      tracked_paths.select! { |p| File.exist?(p) }

      if tracked_paths.empty?
        # So track every sub-dirs except a couple
        # The final '/' in Dir[] makes it return directories only, but they will also end with a '/'
        # So need to include that last '/' in the substracted paths.
        # TODO: We probably want a cleaner way of filtering out some directories. But for now, that's what we got.
        tracked_paths = Dir['./*/'] - %w(./autotest/ ./features/ ./spec/ ./test/ ./bin/ ./exe/)
        # And track every ruby files in the top-level
        tracked_paths << './*.rb'
      end
      tracked_paths
      # path expansion is done in #lookup_globs
    end

    def tracked_file_path?(path)
      return false if lookup_exclusion.match?(path)
      # The flags are to make fnmatch match the same things as Dir.glob... This doesn't seem to be documented anywhere
      # EXTGLOB: allow matching {lib,app} as either lib or app
      # PATHNAME: Makes wildcard match not match /, and make /**/ (and pattern starting with **/) be any number of nested directory
      lookup_globs.any? { |glob| File.fnmatch?(glob, path, File::FNM_EXTGLOB | File::FNM_PATHNAME) }
    end

    def all_tracked_file_paths
      return @all_tracked_file_paths.dup if @all_tracked_file_paths
      paths_found = Dir[*lookup_globs]
      paths_found.select! { |path| path.end_with?('.rb') }
      paths_found.select! { |path| File.file?(path) }
      paths_found.uniq!
      paths_found.reject! { |path| lookup_exclusion.match?(path) }
      @all_tracked_file_paths = paths_found
      @all_tracked_file_paths.dup
    end

    def custom_requirer
      @custom_requirer ||= CustomRequirer.new
    end

    def autoload_tracker
      @autoload_tracker ||= AutoloadTracker.new
    end

    def persistence
      @persistence ||= Persistence.new(config.cache_directory)
    end

    private

    def handle_relative_filename(filename)
      unless Pathname.new(filename).absolute?
        relative_to = File.dirname(caller(2..2).first.partition(/\.rb:\d/).first)
        filename = File.absolute_path(filename, relative_to)
      end
      filename += '.rb' unless filename.end_with? 'rb'
      filename
    end
  end
end
