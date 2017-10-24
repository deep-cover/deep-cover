# TODO: must handle circular requires

module DeepCover
  class CustomRequirer
    attr_reader :load_path, :loaded_features
    def initialize(load_path=$LOAD_PATH, loaded_features=$LOADED_FEATURES)
      @load_path = load_path
      @loaded_features = loaded_features
    end

    # Returns a path to an existing file or nil if none can be found.
    # The search follows how ruby search for files using the $LOAD_PATH
    #
    # An absolute path is returned directly if it exists, otherwise nil
    # is returned without searching anywhere else.
    def resolve_path(path)
      path = File.absolute_path(path) if path.start_with?('./') || path.start_with?('../')

      if Pathname.new(path).absolute?
        return path if File.exists?(path)
        return nil
      end

      @load_path.each do |load_path|
        possible_path = File.absolute_path(path, load_path)
        return possible_path if File.exists?(possible_path)
      end

      nil
    end

    # Homemade #require to be able to instrument the code before it gets executed.
    # Returns true when everything went right. (Same as regular ruby)
    # Returns false when the found file was already required. (Same as regular ruby)
    # Returns :not_found if the file couldn't be found.
    #     Caller should delegate to the default #require.
    # Returns :cover_failed if DeepCover couldn't apply instrumentation the file found.
    #     Caller should delegate to the default #require.
    # Returns :not_supported for files that are not supported (such as ike .so files)
    #     Caller should delegate to the default #require.
    # Exceptions raised by the required code bubble up as normal.
    #     It is *NOT* recommended to simply delegate to the default #require, since it
    #     might not be safe to run part of the code again.
    def require(path)
      ext = File.extname(path)
      return :not_supported if ext == '.so'
      path = path + '.rb' if ext != '.rb'
      return false if @loaded_features.include?(path)

      found_path = resolve_path(path)

      return :not_found unless found_path
      return false if @loaded_features.include?(found_path)

      covered_code = cover_and_execute(found_path)
      return covered_code if covered_code.is_a?(Symbol)

      @loaded_features << found_path
      true
    end

    # Homemade #load to be able to instrument the code before it gets executed.
    # Note, this doesn't support the `wrap` parameter that ruby's #load has.
    # Same return/raise as CustomRequirer#require, except:
    # Cannot return false since #load doesn't care about a file already being executed.
    def load(path)
      found_path = resolve_path(path)

      if found_path.nil?
        # #load has a final fallback of always trying relative to current work directory of process
        possible_path = File.absolute_path(path)
        found_path = possible_path if File.exists?(possible_path)
      end

      return :not_found unless found_path

      covered_code = cover_and_execute(found_path)
      return covered_code if covered_code.is_a?(Symbol)

      true
    end

    protected
    def cover_and_execute(path)
      covered_code = DeepCover.coverage.covered_code(path)
      return :cover_failed unless covered_code
      DeepCover.autoload_tracker.wrap_require(path) do
        covered_code.execute_code
      end
      covered_code
    end
  end
end
