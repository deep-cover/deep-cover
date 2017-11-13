# frozen_string_literal: true

# rubocop:disable Style/MixinUsage (See https://github.com/bbatsov/rubocop/issues/5055)
module DeepCover
  require 'parser'
  require 'term/ansicolor'
  require 'pry'
  require_relative 'deep_cover/backports'
  require_relative 'deep_cover/tools'
  require_relative_dir 'deep_cover/parser_ext'
  require_relative_dir 'deep_cover', except: %w[auto_run builtin_takeover]

  extend Base
  extend Config::Setter
end
DeepCover::GLOBAL_BINDING = binding
