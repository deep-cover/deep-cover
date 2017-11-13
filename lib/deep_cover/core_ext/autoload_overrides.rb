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

module DeepCover
  module KernelAutoloadOverride
    def autoload(name, path)
      mod = binding.of_caller(1).eval('Module.nesting').first || Object
      DeepCover.autoload_tracker.add(mod, name, path)
      mod.autoload_without_deep_cover(name, path)
    end

    extend ModuleOverride
    override ::Kernel, ::Kernel.singleton_class
  end

  module ModuleAutoloadOverride
    def autoload(name, path)
      DeepCover.autoload_tracker.add(self, name, path)
      autoload_without_deep_cover(name, path)
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
