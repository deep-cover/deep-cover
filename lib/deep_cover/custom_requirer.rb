# frozen_string_literal: true

module DeepCover
  class CustomRequirer
    class LoadPathsSubset
      def initialize(load_paths:, lookup_paths:)
        @original_load_paths = load_paths
        @cached_load_paths_subset = []
        @cached_load_paths_hash = nil
        @lookup_paths = lookup_paths.map { |p| File.expand_path(p) }
      end

      def load_paths
        if @cached_load_paths_hash != (h = @original_load_paths.hash)
          @cached_load_paths_subset = compute_subset
          @cached_load_paths_hash = h
        end
        @cached_load_paths_subset
      end

      # E.g.  '/a/b/' => true if a lookup path is '/a/b/c/', because '/a/b/' + 'c/ok' is within lookup.
      def potentially_within_lookup?(full_dir_path)
        @lookup_paths.any? { |p| p.start_with? full_dir_path }
      end

      # E.g.  '/a/b' => true when a lookup path is '/a/'
      def within_lookup?(full_path)
        @lookup_paths.any? { |p| full_path.start_with?(p) }
      end

      def exist?(full_path)
        within_lookup?(full_path) && File.exist?(full_path)
      end

      private

      def compute_subset
        @original_load_paths.map { |p| File.expand_path(p) }
                            .select { |p| within_lookup?(p) || potentially_within_lookup?(p) }
                            .freeze
      end
    end

    class EveryLoadPaths
      attr_reader :load_paths
      def initialize(load_paths)
        @load_paths = load_paths
      end

      def exist?(full_path)
        File.exist?(full_path)
      end

      def within_lookup?(full_path)
        true
      end
    end

    attr_reader :load_paths, :loaded_features, :filter
    def initialize(load_paths: $LOAD_PATH, loaded_features: $LOADED_FEATURES, lookup_paths: nil, &filter)
      @load_paths = load_paths
      lookup_paths ||= Dir.getwd
      lookup_paths = Array(lookup_paths)

      if lookup_paths.include?('/')
        @load_paths_subset = EveryLoadPaths.new(load_paths)
      else
        @load_paths_subset = LoadPathsSubset.new(load_paths: load_paths, lookup_paths: lookup_paths)
      end

      @loaded_features = loaded_features
      @filter = filter
      @paths_being_required = Set.new
    end

    # Returns a path to an existing file or nil if none can be found.
    # The search follows how ruby search for files using the $LOAD_PATH, but limits
    # those it checks based on the LoadPathsSubset.
    #
    # An absolute path is returned directly if it exists, otherwise nil is returned
    # without searching anywhere else.
    def resolve_path(path, extensions_to_try = ['.rb', '.so'])
      if extensions_to_try
        extensions_to_try = [''] if extensions_to_try.any? { |ext| path.end_with?(ext) }
      else
        extensions_to_try = ['']
      end

      abs_path = File.absolute_path(path)
      path = abs_path if path.start_with?('./', '../')

      paths_with_ext = extensions_to_try.map { |ext| path + ext }

      if path == abs_path
        paths_with_ext.each do |path_with_ext|
          return path_with_ext if @loaded_features.include?(path_with_ext)
        end

        paths_with_ext.each do |path_with_ext|
          return path_with_ext if File.exist?(path_with_ext)
        end
      else
        possible_paths = paths_with_load_paths(paths_with_ext)
        possible_paths.each do |possible_path|
          return possible_path if @loaded_features.include?(possible_path)
        end

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
    def require(path, &fallback_block)
      path = path.to_s

      found_path = resolve_path(path)

      DeepCover.autoload_tracker.wrap_require(path, found_path) do
        return yield(:not_found) unless found_path

        return false if @loaded_features.include?(found_path)
        return false if @paths_being_required.include?(found_path)

        begin
          @paths_being_required.add(found_path)
          return yield(:not_in_covered_paths) unless @load_paths_subset.within_lookup?(found_path)
          return yield(:not_supported) if found_path.end_with?('.so')
          return yield(:skipped) if filter && filter.call(found_path)

          cover_and_execute(found_path) { |reason| return yield(reason) }

          @loaded_features << found_path
        ensure
          @paths_being_required.delete(found_path)
        end
      end
      true
    end

    ### Not currently used ###
    # Homemade #load to be able to instrument the code before it gets executed.
    # Note, this doesn't support the `wrap` parameter that ruby's #load has.
    # Same return/throw as CustomRequirer#require, except:
    # Cannot return false since #load doesn't care about a file already being executed.
    def load(path, &fallback_block)
      found_path = resolve_path(path, nil)

      if found_path.nil?
        # #load has a final fallback of always trying relative to current work directory of process
        possible_path = File.absolute_path(path)
        found_path = possible_path if File.exist?(possible_path)
      end

      return yield(:not_found) unless found_path

      cover_and_execute(found_path) { |reason| return yield(reason) }

      true
    end

    def is_being_required?(path)
      found_path = resolve_path(path)
      @paths_being_required.include?(found_path)
    end

    protected

    def paths_with_load_paths(paths)
      paths.flat_map do |path|
        @load_paths.map do |load_path|
          File.absolute_path(path, load_path)
        end
      end
    end

    def cover_and_execute(path, &fallback_block)
      begin
        covered_code = DeepCover.coverage.covered_code(path)
      rescue Parser::SyntaxError => e
        if e.message =~ /contains escape sequences incompatible with UTF-8/
          warn "Can't cover #{path} because of incompatible encoding (see issue #9)"
        else
          warn "The file #{path} can't be instrumented"
        end
        yield(:cover_failed)
        raise "The fallback_block is supposed to either return or break, but didn't do either"
      end
      begin
        covered_code.execute_code
      rescue ::SyntaxError => e
        warn ["DeepCover is getting confused with the file #{path} and it won't be instrumented.",
              'Please report this error and provide the source code around the following:',
              e,
             ].join("\n")
        yield(:cover_failed)
        raise "The fallback_block is supposed to either return or break, but didn't do either"
      end
      covered_code
    end
  end
end
