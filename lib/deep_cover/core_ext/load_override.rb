# These are the monkeypatches to replace the default #load in order
# to instrument the code before it gets run.

class << Kernel
  alias_method :load_without_coverage, :load
  def load(path, wrap = false)
    return load_without_coverage(path, wrap) if wrap

    result = DeepCover.custom_requirer.load(path)
    if [:not_found, :cover_failed].include?(result)
      load_without_coverage(path)
    else
      result
    end
  end
end

module Kernel
  def load(path, wrap = false)
    Kernel.require(path, wrap)
  end
end
