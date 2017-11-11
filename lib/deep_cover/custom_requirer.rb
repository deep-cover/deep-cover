# TODO: must handle circular requires

module DeepCover
  class CustomRequirer
    attr_reader :load_paths, :loaded_features
    def initialize(load_paths: $LOAD_PATH, loaded_features: $LOADED_FEATURES)
      @load_paths = load_paths
      @loaded_features = loaded_features
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
        return path if File.exist?(path)
        return nil
      end

      @load_paths.each do |load_path|
        possible_path = File.absolute_path(path, load_path)
        return possible_path if File.exist?(possible_path)
      end

      nil
    end

    # Homemade #require to be able to instrument the code before it gets executed.
    # Returns true when everything went right. (Same as regular ruby)
    # Returns false when the found file was already required. (Same as regular ruby)
    # Throws :use_fallback in case caller should delegate to the default #require.
    # Reasons given could be:
    #  - :not_found if the file couldn't be found.
    #  - :cover_failed if DeepCover couldn't apply instrumentation the file found.
    #  - :not_supported for files that are not supported (such as ike .so files)
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
        found_path = possible_path if File.exist?(possible_path)
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
