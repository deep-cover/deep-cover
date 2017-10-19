require 'weakref'

module DeepCover
  class AutoloadTracker
    def initialize(autoloaded_paths = {})
      @autoloaded_paths = autoloaded_paths
    end

    def add(const, name, path)
      ext = File.extname(path)
      # We don't care about .so files
      return if ext == '.so'
      path = path + '.rb' if ext != '.rb'

      pairs = @autoloaded_paths[path] ||= []
      pairs << [WeakRef.new(const), name]
    end

    def pairs_for_absolute_path(absolute_path)
      paths = autoloaded_paths_matching_absolute(absolute_path)

      paths.flat_map do |path|
        pairs = @autoloaded_paths[path] || []
        pairs = pairs.map{|weak_const, name| [self.class.value_from_weak_ref(weak_const), name] }
        pairs.select!(&:first)
        pairs
      end
    end

    def wrap_require(absolute_path)
      pairs = pairs_for_absolute_path(absolute_path)

      begin
        pairs.each do |const, name|
          # Changing the autoload to an already loaded file (this one)
          const.autoload_without_coverage(name, __FILE__)
        end

        yield
      rescue Exception
        pairs.each do |const, name|
          # Changing the autoload to an already loaded file (this one)
          const.autoload_without_coverage(name, absolute_path)
        end

        raise
      end
    end

    def initialize_autoloaded_paths
      @autoloaded_paths = {}
      ObjectSpace.each_object(Module) do |mod|
        mod.constants.each do |name|
          if path = mod.autoload?(name)
            add(mod, name, path)
          end
        end
      end
    end

    # We need all the paths of autoloaded_path that match a given absolute_path
    # Since this can happen a lot, a cache is made which only chan
    def autoloaded_paths_matching_absolute(absolute_path)
      @autoloaded_paths.keys.select do |path|
        absolute_path == DeepCover.custom_requirer.resolve_path(path)
      end
    end

    # A simple if the ref is dead, return nil.
    # WTF ruby, why is there no such simple interface ?!
    def self.value_from_weak_ref(weak_ref)
      WeakRef.class_variable_get(:@@__map)[weak_ref]
    end
  end
end
