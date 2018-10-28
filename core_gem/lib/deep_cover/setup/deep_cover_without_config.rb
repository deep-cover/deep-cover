# frozen_string_literal: true

# This file is called from `require 'deep-cover'`
#
# This setups the DeepCover environment code-wise.

module DeepCover
  require_relative '../load'

  load_absolute_basics

  extend Base
  extend ConfigSetter
end
DeepCover::GLOBAL_BINDING = binding
