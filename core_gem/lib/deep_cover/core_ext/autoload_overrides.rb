# frozen_string_literal: true

# Autoload is quite difficult to hook into to do what we need to do.
#
# We create a temporary file that gets set as path for autoloads. The file then does a require of the
# autoloaded file. We also keep track of autoloaded constants and files and change the autoload's target when
# those files get required (or when we guess they are being).
#
# Doing it this way solves:
#
# * When autoload is triggered, it doesn't always call `require`. In Ruby 2.1 and 2.2, it just loads the
#   file somehow without using require, this means we can't instrument autoloaded files. Using an intercept
#   file means that the intercept is not covered (we don't care) and then the manual require will
#   allow us to instrument the real target.
#
# * When autoload is triggered, there are special states setup internal to ruby to allow constants to
#   be used conditionally. If the target file is not actually required (such as when using our custom requirer),
#   then the state is not correct and we can't do simple things such as `A ||= 1` or `module A; ...; end`.
#   This problem was happening when all we did was use the custom require that does get called for Ruby 2.3+.
#
#   To solve the issues, we keep track of all the autoloads, and when we detect that a file is being autoloaded,
#   we change the state so that ruby thinks the file was already loaded.
#
# * An issue with the interceptor files is that if some code manually requires a file that is the target of
#   autoloading, ruby would not disable the autoload behavior, and would end up trying to autoload once the constant
#   is reached.
#
#   To solve this, every require, we check if it is for a file that is is meant to autoload a constant, and if so,
#   we remove that autoload.
#
# * To make matter more complicated, when loading gems without bundle's setup, the $LOAD_PATH is filled by RubyGems
#   as part of a monkey-patch of Kernel#require. Because of this, we can't always find the file that will be required,
#   even though a file will indeed be required.
#
#   However, if nothing is done, the autoload can cause problems on that built-in require (as explained in a previous
#   point). So when we don't find the target, we check if it's a require that will go through the $LOAD_PATH,
#   meaning that require's parameter is not an absolute path, and isn't relative to the current directory (so doesn't
#   start with './' or '../').
#
#   When a require does go through $LOAD_PATH, we do a best effort to deactivate the autoloads that seem to match
#   to match this require by comparing the required path (as it is received) to all the autoload path we have, and
#   deactivating those that match. This is only an issue when there is an autoload made which will load a different
#   gem. This is pretty rare (but deep-cover does it...)
#
# * All of this changing autoloads means that for modules/classes that are frozen, we can't handle the situation, since
#   we can't change the autoload stuff.
#
#   We don't resolve this problem. However, we could work around it by always calling the real require for these
#   files (which means we wouldn't cover them), and by not creating interceptor files for the autoloads. Since we
#   can't know when the #autoload call is made, if the constant will be frozen later on, we would have to instead
#   monkey-patch #freeze on modules and classes to remove the interceptor file before things get frozen.
#
# * Kernel#autoload uses the caller's `Module.nesting` instead of using self.
#   This means that if we intercept the autoload, then we cannot call the original Kernel#autoload because it will
#   now use our Module instead if our caller's. The only reliable solution we've found to this is to use binding_of_caller
#   to get the correct object to call autoload on.
#
#   (This is not a problem with Module#autoload and Module.autoload)
#
#   A possible solution to investigate is to make a simple C extension, to do the work of our monkey-patch, this way,
#   the check for the caller doesn't find our callstack
#
# Some situations where Module.nesting of the caller is different from self in Kernel#autoload:
# * When in the top-level: (self: main) vs (Module.nesting: nil, which we default to Object)
# * When called from a method defined on a module that is included:
#     module A
#       def begin_autoload
#         # `Kernel.autoload` would have the same result
#         autoload :A1, 'hello'
#       end
#     end
#     class B
#       include A
#     end
#   Calling `B.new.begin_autoload` is equivalent to:
#     A.autoload :A1, 'hello'
#   NOT this:
#     B.autoload :A1, 'hello'
#
require 'binding_of_caller'
require 'tempfile'

module DeepCover
  load_all

  module KernelAutoloadOverride
    if RUBY_PLATFORM == 'java'
      # JRuby has different semantics for Kernel.autoload and Kernel#autoload
      def autoload(name, path)
        if Kernel.equal?(self)
          # Yeah, this is weird
          # https://github.com/jruby/jruby/issues/5466
          mod = Object.singleton_class
        elsif self.is_a?(Module)
          mod = self
        else
          mod = self.class
        end
        autoload_path = DeepCover.autoload_tracker.autoload_path_for(mod, name, path)
        mod.autoload_without_deep_cover(name, autoload_path)
      end
    else
      def autoload(name, path)
        mod = binding.of_caller(1).eval('Module.nesting').first || Object
        autoload_path = DeepCover.autoload_tracker.autoload_path_for(mod, name, path)
        mod.autoload_without_deep_cover(name, autoload_path)
      end
    end

    extend ModuleOverride
    override ::Kernel, ::Kernel.singleton_class
  end

  module ModuleAutoloadOverride
    def autoload(name, path)
      autoload_path = DeepCover.autoload_tracker.autoload_path_for(self, name, path)
      autoload_without_deep_cover(name, autoload_path)
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
