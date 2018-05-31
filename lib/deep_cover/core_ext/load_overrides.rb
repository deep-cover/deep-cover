# frozen_string_literal: true

# These are the monkeypatches to replace the default #load in order
# to instrument the code before it gets run.
# For now, this is not used, and may never be. The tracking and reporting for things can might be
# loaded multiple times can be complex and is beyond the current scope of the project.

module DeepCover
  module LoadOverride
    def load(path, wrap = false)
      return load_without_deep_cover(path, wrap) if wrap

      DeepCover.custom_requirer.load(path) { load_without_deep_cover(path) }
    end

    extend ModuleOverride
    override ::Kernel, ::Kernel.singleton_class
  end
end
