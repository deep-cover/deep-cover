# frozen_string_literal: true

# We create a temporary file that gets set as path for autoloads. The file then does a require of the
# autoloaded file.
#
# Doing it this way solves:
#
# * When autoload is triggered, it doesn't always call `require`. In Ruby 2.1 and 2.2, it just loads the
#   file somehow without using require, this means we can't intrument autoloaded files. Using a intercept
#   file means that the intercept is not covered (we don't care) and then the manual require will
#   allow us to instrument to real target.
#
# * When autoload is triggered, there are special states setup internall to ruby to allow constants to
#   be used conditionally. If the target file is not actually required (such as when using our custom requirer),
#   then the state is not correct and we can't do simple thigns such as `A ||= 1` or `module A; ...; end`.
#   This problem was happening when all we did was use the custom require that does get called for Ruby 2.3+.
#
#   To solve the issue, in the past, we had to make a somewhat complex tracker of autoloaded files and, before
#   requiring any file, we would change every autoload that point to this file to another file that is already
#   fully required. This way, Ruby's internals would be similar to what they should be and things would work properly.
#
#   The way this new method with the intercept files solve this issue, is that because the files are tempfiles,
#   they are not created in the directories that Deep-Cover tracks. Therefore, if its require is called by autoload,
#   such as in Ruby 2.3+, it will not try to instrument it, and will instead call the regular require, which will
#   set the state correctly.
#
# Another challenge of autoload is that Kernel#autoload uses the caller's `Module.nesting` instead of using self.
# This means that if we intercept the autoload, then we cannot call the original Kernel#autoload because it will
# now use our Module instead if our caller's. The only reliable solution we've found to this is to use binding_of_caller
# to get the correct object to call autoload on.
#
# Some situations where Module.nesting of the caller is different from self in Kernel#autoload:
# * When in the top-level: (self: main) vs (Module.nesting: nil, which we default to Object)
# * When called from a method of the module:
#     module A
#       def begin_autoload
#         autoload :A1, 'hello'
#       end
#     end
#   Calling #begin_autoload on an instance of a class `B` that `include A` results in:
#     A.autoload :A1, 'hello'
#   NOT this:
#     B.autoload :A1, 'hello'
#

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
