# These are the monkeypatches to replace the default #require and
# #require_relative in order to instrument the code before it gets run.
# Kernel.require and Kernel#require must both have their version because
# each can have been already overwritten individually. (Rubygems only
# overrides Kernel#require)

class << Kernel
  alias_method :require_without_coverage, :require
  def require(path)
    result = DeepCover.custom_requirer.require(path)
    if [:not_found, :cover_failed, :not_supported].include?(result)
      require_without_coverage(path)
    else
      result
    end
  end

  def require_relative(path)
    base = caller(1..1).first[/[^:]+/]
    raise LoadError, "cannot infer basepath" unless base
    base = File.dirname(base)

    require(File.absolute_path(path, base))
  end
end

module Kernel
  alias_method :require_without_coverage, :require
  def require(path)
    result = DeepCover.custom_requirer.require(path)
    if [:not_found, :cover_failed, :not_supported].include?(result)
      require_without_coverage(path)
    else
      result
    end
  end

  def require_relative(path)
    base = caller(1..1).first[/[^:]+/]
    raise LoadError, "cannot infer basepath" unless base
    base = File.dirname(base)

    require(File.absolute_path(path, base))
  end
end
