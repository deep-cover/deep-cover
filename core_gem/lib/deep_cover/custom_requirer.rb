# frozen_string_literal: true

module DeepCover
  class CustomRequirer
    attr_reader :load_paths, :loaded_features, :filter
    def initialize(load_paths: $LOAD_PATH, loaded_features: $LOADED_FEATURES, &filter)
      @load_paths = load_paths
      @loaded_features = loaded_features
      @filter = filter
      @paths_being_required = Set.new

      # A Set of the loaded_features for faster access
      @loaded_features_set = Set.new
      # A dup of the loaded_features as they are expected to be for the Set to be valid
      # If this is different from loaded_features, the set should be refreshed
      @duped_loaded_features_used_for_set = []
    end

    # Returns a path to an existing file or nil if none can be found.
    # The search follows how ruby search for files using the $LOAD_PATH, but limits
    # those it checks based on the LoadPathsSubset.
    #
    # An absolute path is returned directly if it exists, otherwise nil is returned
    # without searching anywhere else.
    def resolve_path(path, try_extensions: true)
      extensions_to_try = if try_extensions && !REQUIRABLE_EXTENSIONS.include?(File.extname(path))
                            REQUIRABLE_EXTENSION_KEYS
                          else
                            ['']
                          end

      abs_path = File.absolute_path(path)
      path = abs_path if path.start_with?('./', '../')

      paths_with_ext = extensions_to_try.map { |ext| path + ext }

      refresh_loaded_features_set

      # Doing this check in every case instead of only for absolute_path because ruby has some
      # built-in $LOADED_FEATURES which aren't an absolute path. Ex: enumerator.so, thread.rb
      path_from_loaded_features = first_path_from_loaded_features_set(paths_with_ext)
      return path_from_loaded_features if path_from_loaded_features

      if path == abs_path
        paths_with_ext.each do |path_with_ext|
          next unless File.exist?(path_with_ext)

          # https://github.com/jruby/jruby/issues/5465
          path_with_ext = File.realpath(path_with_ext) if RUBY_PLATFORM == 'java' && Gem::Version.new(JRUBY_VERSION) >= Gem::Version.new('9.2.5')
          return path_with_ext
        end
      else
        possible_paths = paths_with_load_paths(paths_with_ext)
        path_from_loaded_features = first_path_from_loaded_features_set(possible_paths)
        return path_from_loaded_features if path_from_loaded_features

        possible_paths.each do |possible_path|
          next unless File.exist?(possible_path)
          # Ruby 2.5 changed some behaviors of require related to symlinks in $LOAD_PATH
          # https://bugs.ruby-lang.org/issues/10222
          return File.realpath(possible_path) if RUBY_VERSION >= '2.5'
          return possible_path
        end
      end
      nil
    end

    # Homemade #require to be able to instrument the code before it gets executed.
    # Returns true when everything went right. (Same as regular ruby)
    # Returns false when the found file was already required. (Same as regular ruby)
    # Calls &fallback_block with the reason as parameter if the work couldn't be done.
    # The possible reasons are:
    #  - :not_found if the file couldn't be found.
    #  - :not_in_covered_paths if the file is not in the paths to cover
    #  - :cover_failed if DeepCover couldn't apply instrumentation the file found.
    #  - :not_supported for files that are not supported (such as .so files)
    #  - :skipped if the filter block returned `true`
    # Exceptions raised by the required code bubble up as normal, except for
    # SyntaxError, which is turned into a :cover_failed which calls the fallback_block.
    def require(path) # &fallback_block
      raise 'Should receive the fallback_block' unless block_given?
      path = path.to_s

      found_path = resolve_path(path)

      if found_path
        return false if @loaded_features.include?(found_path)
        return false if @paths_being_required.include?(found_path)
      end

      DeepCover.autoload_tracker.wrap_require(path, found_path) do
        begin
          # Either a problem with resolve_path, or a gem that will be added to the load_path by RubyGems
          return yield(:not_found) unless found_path

          @paths_being_required.add(found_path)
          return yield(:not_in_covered_paths) unless DeepCover.tracked_file_path?(found_path)
          return yield(:not_supported) if REQUIRABLE_EXTENSIONS[File.extname(found_path)] == :native_extension
          return yield(:skipped) if filter && filter.call(found_path)

          cover_and_execute(found_path) { |reason| return yield(reason) }

          @loaded_features << found_path
        ensure
          @paths_being_required.delete(found_path)
          add_last_loaded_feature_to_set
        end
      end
      true
    end

    # Homemade #load to be able to instrument the code before it gets executed.
    # Note, this doesn't support the `wrap` parameter that ruby's #load has.
    # Same yield/return behavior as CustomRequirer#require, except that it
    # cannot return false #load doesn't care about a file already being executed.
    def load(path) # &fallback_block
      raise 'Should receive the fallback_block' unless block_given?
      path = path.to_s

      found_path = resolve_path(path, try_extensions: false)

      if found_path.nil?
        # #load has a final fallback of always trying relative to current work directory
        possible_path = File.absolute_path(path)
        found_path = possible_path if File.exist?(possible_path)
      end

      return yield(:not_found) unless found_path
      return yield(:not_in_covered_paths) unless DeepCover.tracked_file_path?(found_path)

      cover_and_execute(found_path) { |reason| return yield(reason) }

      true
    end

    def is_being_required?(path)
      found_path = resolve_path(path)
      @paths_being_required.include?(found_path)
    end

    protected

    # updates the loaded_features_set if it needs it
    def refresh_loaded_features_set
      return if @duped_loaded_features_used_for_set == @loaded_features

      @duped_loaded_features_used_for_set = @loaded_features.dup
      @loaded_features_set = Set.new(@duped_loaded_features_used_for_set)
    end

    # Returns the first path found in the loaded_features_set
    # Should be called after doing a #refresh_loaded_features_set
    def first_path_from_loaded_features_set(paths)
      paths.detect { |path| @loaded_features_set.include?(path) }
    end

    # Called after a require, adds the last entry of loaded_features to the
    # loaded_features_set and the clone used to check for a need to refresh
    # the loaded_features_set. Doing this allows us to never need to update
    # the loaded_feature_set from scratch (almost? this is a safety precaution)
    def add_last_loaded_feature_to_set
      loaded_feature = @loaded_features.last
      unless @loaded_features_set.include?(loaded_feature)
        @duped_loaded_features_used_for_set << loaded_feature
        @loaded_features_set << loaded_feature
      end
    end

    def paths_with_load_paths(paths)
      paths.flat_map do |path|
        @load_paths.map do |load_path|
          File.absolute_path(path, load_path)
        end
      end
    end

    def cover_and_execute(path) # &fallback_block
      covered_code = DeepCover.coverage.covered_code_or_warn(path)
      if covered_code.nil?
        yield(:cover_failed)
        raise "The fallback_block is supposed to either return or break, but didn't do either"
      end

      success = covered_code.execute_code_or_warn
      unless success
        yield(:cover_failed)
        raise "The fallback_block is supposed to either return or break, but didn't do either"
      end

      covered_code
    end
  end
end
