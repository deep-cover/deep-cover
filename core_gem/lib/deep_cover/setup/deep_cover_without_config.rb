# frozen_string_literal: true

# This file is called from `require 'deep-cover'` and from the CLI
#
# This setups the DeepCover environment code-wise.

module DeepCover
  require_relative '../load'

  load_absolute_basics

  extend Base
  extend ConfigSetter
end
DeepCover::GLOBAL_BINDING = binding
