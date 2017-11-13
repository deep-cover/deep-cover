# frozen_string_literal: true
# TODO: must handle circular requires

module DeepCover
  class CustomRequirer
    class RootedLoadPaths
      def initialize(load_paths: raise, lookup_paths: raise)
        @load_paths = load_paths
        @cached_rooted_load_paths = []
        @cached_load_paths_size = 0
        @lookup_paths = lookup_paths.map{|p| File.expand_path(p)}
      end

      def load_paths
        if @cached_load_paths_size != @load_paths.size
           @cached_rooted_load_paths = @load_paths.map{ |p| File.expand_path(p) }
            .select{|p| within_lookup?(p) || potentially_within_lookup?(p) }
            .freeze
          @cached_load_paths_size = @load_paths.size
        end
        @cached_rooted_load_paths
      end

      # E.g.  '/a/b/' => true if a lookup path is '/a/b/c/', because '/a/b/' + 'c/ok' is within lookup.
      def potentially_within_lookup?(full_dir_path)
        @lookup_paths.any?{|p| p.start_with? full_dir_path }
      end

      # E.g.  '/a/b' => true when a lookup path is '/a/'
      def within_lookup?(full_path)
        @lookup_paths.any?{|p| full_path.start_with? p}
      end

      def exist?(full_path)
        within_lookup?(full_path) && File.exist?(full_path)
      end
    end

    attr_reader :load_paths, :loaded_features, :filter
    def initialize(load_paths: $LOAD_PATH, loaded_features: $LOADED_FEATURES, lookup_paths: nil, &filter)
      @load_paths = load_paths
      lookup_paths ||= Dir.getwd
      lookup_paths = Array(lookup_paths)
      @cache = RootedLoadPaths.new(load_paths: load_paths, lookup_paths: lookup_paths) unless lookup_paths.include? '/'
      @loaded_features = loaded_features
      @filter = filter
    end

    # Returns a path to an existing file or nil if none can be found.
    # The search follows how ruby search for files using the $LOAD_PATH
    #
    # An absolute path is returned directly if it exists, otherwise nil
    # is returned without searching anywhere else.
    def resolve_path(path)
      path = File.absolute_path(path) if path.start_with?('./') || path.start_with?('../')

      abs_path = File.absolute_path(path)
      if path == abs_path
        path if (@cache || File).exist?(path)
      else
        (@cache || self).load_paths.each do |load_path|
          possible_path = File.absolute_path(path, load_path)
          return possible_path if (@cache || File).exist?(possible_path)
        end
        nil
      end
    end

    # Homemade #require to be able to instrument the code before it gets executed.
    # Returns true when everything went right. (Same as regular ruby)
    # Returns false when the found file was already required. (Same as regular ruby)
    # Throws :use_fallback in case caller should delegate to the default #require.
    # Reasons given could be:
    #  - :not_found if the file couldn't be found.
    #  - :cover_failed if DeepCover couldn't apply instrumentation the file found.
    #  - :not_supported for files that are not supported (such as ike .so files)
    #  - :skipped if the filter block returned `true`
    # Exceptions raised by the required code bubble up as normal.
    #     It is *NOT* recommended to simply delegate to the default #require, since it
    #     might not be safe to run part of the code again.
    def require(path)
      ext = File.extname(path)
      throw :use_fallback, :not_supported if ext == '.so'
      path = path + '.rb' if ext != '.rb'
      return false if @loaded_features.include?(path)

      found_path = resolve_path(path)

      throw :use_fallback, :not_found unless found_path
      return false if @loaded_features.include?(found_path)

      throw :use_fallback, :skipped if filter && filter.call(found_path)

      cover_and_execute(found_path)

      @loaded_features << found_path
      true
    end

    # Homemade #load to be able to instrument the code before it gets executed.
    # Note, this doesn't support the `wrap` parameter that ruby's #load has.
    # Same return/throw as CustomRequirer#require, except:
    # Cannot return false since #load doesn't care about a file already being executed.
    def load(path)
      found_path = resolve_path(path)

      if found_path.nil?
        # #load has a final fallback of always trying relative to current work directory of process
        possible_path = File.absolute_path(path)
        found_path = possible_path if (@cache || File).exist?(possible_path)
      end

      throw :use_fallback, :not_found unless found_path

      cover_and_execute(found_path)

      true
    end

    protected
    def cover_and_execute(path)
      begin
        covered_code = DeepCover.coverage.covered_code(path)
      rescue Parser::SyntaxError => e
        if e.message =~ /contains escape sequences incompatible with UTF-8/
          warn "Can't cover #{path} because of incompatible encoding (see issue #9)"
        else
          warn "The file #{path} can't be instrumented"
        end
        throw :use_fallback, :cover_failed
      end
      DeepCover.autoload_tracker.wrap_require(path) do
        begin
          covered_code.execute_code
        rescue ::SyntaxError => e
          warn "DeepCover is getting confused with the file #{path} and it won't be instrumented.\n" +
               "Please report this error and provide the source code around the following:\n#{e}"
          throw :use_fallback, :cover_failed
        end
      end
      covered_code
    end
  end
end
