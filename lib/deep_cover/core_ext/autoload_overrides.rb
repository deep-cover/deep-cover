# frozen_string_literal: true

# We need to override autoload, because MRI has special behaviors associated with it
# that we can't reuse, hence we need to do workarounds.
#
# Basically, when trying to use a constant set to be autoloaded in an optionnal way, like:
#   * module A; ...; end
#   * A ||= 1
# When autoloading the file, the above won't work and will raise a "uninitialized constant A"
# because ruby doesn't understand that custom require is currently requiring the correct file.
#
# Our solution is to track autoloads ourself, and when requiring a path that has autoloads,
# we remove the autoloads from the constants first.

require 'binding_of_caller'
require 'tempfile'

module DeepCover
  module AutoloadInterceptor
    def self.autoload_interceptor_for(path)
      # Need to store all the tempfiles so that they are not GCed, which would delete the files themselves.
      @@interceptor_files ||= []
      new_file = Tempfile.new([File.basename(path), '.rb'])
      @@interceptor_files << new_file
      new_file.write("# Intermediary file for ruby's autoload made by deepcover\nrequire #{path.to_s.inspect}")
      new_file.close

      new_file.path
    end
  end

  module KernelAutoloadOverride
    def autoload(name, path)
      mod = binding.of_caller(1).eval('Module.nesting').first || Object
      interceptor_path = AutoloadInterceptor.autoload_interceptor_for(path)
      mod.autoload_without_deep_cover(name, interceptor_path)
    end

    extend ModuleOverride
    override ::Kernel, ::Kernel.singleton_class
  end

  module ModuleAutoloadOverride
    def autoload(name, path)
      interceptor_path = AutoloadInterceptor.autoload_interceptor_for(path)
      autoload_without_deep_cover(name, interceptor_path)
    end

    extend ModuleOverride
    override Module
  end

  module AutoloadOverride
    def self.active=(flag)
      KernelAutoloadOverride.active = ModuleAutoloadOverride.active = flag
    end
  end
end
