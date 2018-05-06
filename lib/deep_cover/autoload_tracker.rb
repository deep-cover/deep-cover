# frozen_string_literal: true

require 'weakref'

module DeepCover
  class AutoloadTracker
    AutoloadEntry = Struct.new(:weak_const, :name, :target_path, :interceptor_path) do
      def const
        # If the ref is dead, will return nil, otherwise the target
        WeakRef.class_variable_get(:@@__map)[weak_const]
      end
    end

    attr_reader :autoloads_by_basename, :interceptor_files
    def initialize
      @autoloads_by_basename = {}
      @interceptor_files = []
    end

    def setup_interceptor_for(const, name, path)
      interceptor_path = autoload_interceptor_for(path)
      entry = AutoloadEntry.new(WeakRef.new(const), name, path, interceptor_path)

      basename = basename_without_extension(path)

      @autoloads_by_basename[basename] ||= []
      @autoloads_by_basename[basename] << entry
      interceptor_path
    end

    def possible_autoload_target?(requested_path)
      basename = basename_without_extension(requested_path)
      autoloads = @autoloads_by_basename[basename]
      autoloads && !autoloads.empty?
    end

    def wrap_require(requested_path, absolute_path_found, &block)
      entries = entries_for_target(requested_path, absolute_path_found)

      begin
        entries.each do |entry|
          const = entry.const
          next unless const
          # We set the autoload to a file that is already loaded, this makes ruby happy
          const.autoload_without_deep_cover(entry.name, $LOADED_FEATURES.first)
        end

        return_value = yield
        reached_end = true
        return_value
      ensure
        if !reached_end
          entries.each do |entry|
            const = entry.const
            next unless const
            # Putting the autoloads back back since we couldn't complete the require
            const.autoload_without_deep_cover(entry.name, entry.interceptor_path)
          end
        end
      end
    end

    # This is only used on MRI, so ObjectSpace is alright.
    def initialize_autoloaded_paths(consts = ObjectSpace.each_object(Module), &do_autoload_block)
      consts.each do |const|
        # Module's constants are shared with Object. But if you set autoloads directly on Module, they
        # appear on multiple classes. So just skip, Object will take care of those.
        next if const == Module
        next if const.frozen?
        const.constants.each do |name|
          path = const.autoload?(name)
          next unless path
          interceptor_path = setup_interceptor_for(const, name, path)
          yield const, name, interceptor_path
        end
      end
    end

    # We need to remove the interceptor hooks, otherwise, the problem if manually requiring
    # something that is autoloaded will cause issues.
    def remove_interceptors(&do_autoload_block)
      @autoloads_by_basename.each do |basename, entries|
        entries.each do |entry|
          const = entry.const
          next unless const
          # Module's constants are shared with Object. But if you set autoloads directly on Module, they
          # appear on multiple classes. So just skip, Object will take care of those.
          next if const == Module
          next if const.frozen?
          yield const, entry.name, entry.target_path
        end
      end

      @autoloaded_paths = {}
      @interceptor_files = []
    end

    protected

    def entries_for_target(requested_path, absolute_path_found)
      basename = basename_without_extension(requested_path)
      autoloads = @autoloads_by_basename[basename] || []

      autoloads.select { |entry| entry_is_target?(entry, requested_path, absolute_path_found) }
    end

    def entry_is_target?(entry, requested_path, absolute_path_found)
      return true if entry.target_path == requested_path
      target_path_rb = with_rb_extension(entry.target_path)
      return true if target_path_rb == requested_path

      # Even though this is not efficient, it's safer to resolve entries' target_path each time
      # instead of storing the result, in case subsequent changes to $LOAD_PATH gives different results
      entry_absolute_path = DeepCover.custom_requirer.resolve_path(entry.target_path)
      return true if entry_absolute_path == absolute_path_found
      false
    end

    def basename_without_extension(path)
      new_path = File.basename(path)
      new_path = new_path[0...-3] unless needs_extension?(new_path)
      new_path
    end

    def with_rb_extension(path)
      path += '.rb' unless needs_extension?(path)
      path
    end

    def needs_extension?(path)
      !path.end_with?('.rb', '.so')
    end

    def autoload_interceptor_for(path)
      new_file = Tempfile.new([File.basename(path), '.rb'])
      # Need to store all the tempfiles so that they are not GCed, which would delete the files themselves.
      @interceptor_files << new_file
      new_file.write(<<-RUBY)
# Intermediary file for ruby's autoload made by deep-cover
require #{path.to_s.inspect}
      RUBY
      new_file.close

      new_file.path
    end
  end
end
