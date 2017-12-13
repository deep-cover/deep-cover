# frozen_string_literal: true

# rubocop:disable Style/MixinUsage (See https://github.com/bbatsov/rubocop/issues/5055)
module DeepCover
  require_relative 'deep_cover/load'

  load_absolute_basics

  extend Base
  extend Config::Setter
end
DeepCover::GLOBAL_BINDING = binding
