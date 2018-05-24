# frozen_string_literal: true

require 'weakref'

# TODO: if a constant is removed, AutoloadEntries should be removed

module DeepCover
  class AutoloadTracker
    AutoloadEntry = Struct.new(:weak_const, :name, :target_path, :interceptor_path) do
      # If the ref is dead, will return nil, otherwise the target
      def const
        weak_const.__getobj__
      rescue RefError
        nil
      end
    end

    attr_reader :autoloads_by_basename, :interceptor_files_by_path
    def initialize
      @autoloads_by_basename = {}
      @interceptor_files_by_path = {}
    end

    def autoload_path_for(const, name, path)
      interceptor_path = setup_interceptor_for(const, name, path)

      if DeepCover.custom_requirer.is_being_required?(path)
        $LOADED_FEATURES.first
      else
        interceptor_path
      end
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
          if const.frozen?
            warn_frozen_module(const)
            next
          end
          # We set the autoload to a file that is already loaded, this makes ruby happy
          const.autoload_without_deep_cover(entry.name, $LOADED_FEATURES.first)
        end

        yield
      ensure
        entries = entries_for_target(requested_path, absolute_path_found)
        entries.each do |entry|
          const = entry.const
          next unless const
          if const.frozen?
            warn_frozen_module(const)
            next
          end
          # Putting the autoloads back back since we couldn't complete the require
          const.autoload_without_deep_cover(entry.name, entry.interceptor_path)
        end
      end
    end

    # This is only used on MRI, so ObjectSpace is alright.
    def initialize_autoloaded_paths(consts = ObjectSpace.each_object(Module), &do_autoload_block)
      consts.each do |const|
        # Module's constants are shared with Object. But if you set autoloads directly on Module, they
        # appear on multiple classes. So just skip, Object will take care of those.
        next if const == Module

        if const.frozen?
          if const.constants.any? { |name| const.autoload?(name) }
            warn_frozen_module(const)
          end
          next
        end

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
          if const.frozen?
            warn_frozen_module(const)
            next
          end
          yield const, entry.name, entry.target_path
        end
      end

      @autoloaded_paths = {}
      @interceptor_files_by_path = {}
    end

    protected

    def setup_interceptor_for(const, name, path)
      interceptor_path = autoload_interceptor_for(path)
      entry = AutoloadEntry.new(WeakRef.new(const), name, path, interceptor_path)

      basename = basename_without_extension(path)

      @autoloads_by_basename[basename] ||= []
      @autoloads_by_basename[basename] << entry
      interceptor_path
    end

    def entries_for_target(requested_path, absolute_path_found)
      basename = basename_without_extension(requested_path)
      autoloads = @autoloads_by_basename[basename] || []

      if absolute_path_found
        autoloads.select { |entry| entry_is_target?(entry, requested_path, absolute_path_found) }
      elsif requested_path == File.absolute_path(requested_path)
        []
      elsif requested_path.start_with?('./', '../')
        []
      else
        # We didn't find a path that goes through the $LOAD_PATH
        # It's possible that RubyGems will actually add the $LOAD_PATH and require an actual file
        # So we must make a best-guest for possible matches
        requested_path_to_compare = without_extension(requested_path)
        autoloads.select { |entry| requested_path_to_compare == without_extension(entry.target_path) }
      end
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
      without_extension(File.basename(path))
    end

    def with_rb_extension(path)
      path += '.rb' unless needs_extension?(path)
      path
    end

    def without_extension(path)
      path = path[0...-3] unless needs_extension?(path)
      path
    end

    def needs_extension?(path)
      !path.end_with?('.rb', '.so')
    end

    def autoload_interceptor_for(path)
      existing_files = @interceptor_files_by_path[path] || []
      reusable_file = existing_files.detect { |f| !$LOADED_FEATURES.include?(f.path) }
      return reusable_file.path if reusable_file

      new_file = Tempfile.new([File.basename(path), '.rb'])
      # Need to store all the tempfiles so that they are not GCed, which would delete the files themselves.
      # Keeping them by path allows us to reuse them.
      @interceptor_files_by_path[path] ||= []
      @interceptor_files_by_path[path] << new_file
      new_file.write(<<-RUBY)
# Intermediary file for ruby's autoload made by deep-cover
require #{path.to_s.inspect}
      RUBY
      new_file.close

      new_file.path
    end

    class << self
      # Can be true, false, or a Symbol. The symbol will make every warning be displayed
      attr_accessor :warned_for_frozen_module
    end
    self.warned_for_frozen_module = false

    # Using frozen modules/classes is almost unheard of, but a warning makes things easier if someone does it
    def warn_frozen_module(const)
      return if self.class.warned_for_frozen_module == true
      self.class.warned_for_frozen_module ||= true
      warn "There is an autoload on a frozen module/class: #{const}, DeepCover cannot handle those, failure is probable. " \
           "This warning won't be displayed again (even for different module/class)"
    end
  end
end
