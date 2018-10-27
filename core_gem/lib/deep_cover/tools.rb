# frozen_string_literal: true

module DeepCover
  module Tools
  end

  require_relative 'tools/require_relative_dir'
  extend Tools::RequireRelativeDir
  require_relative_dir 'tools'

  # The functions defined in the submodules of Tools can be accessed
  # either by extending the desired module, or all of them by extending
  # Tools, or by calling them directly Tool.my_function.
  module Tools
    constants.each do |module_name|
      include const_get(module_name)
    end
    extend self
  end
end
