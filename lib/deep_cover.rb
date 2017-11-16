# frozen_string_literal: true

# rubocop:disable Style/MixinUsage (See https://github.com/bbatsov/rubocop/issues/5055)
module DeepCover
  # External dependencies (ex parser)
  require 'parser'
  require 'term/ansicolor'
  require 'pry'

  # Bootstrapping
  require_relative 'deep_cover/backports'
  require_relative 'deep_cover/tools'

  # Parser
  silence_warnings do
    require 'parser/current'
  end
  require_relative_dir 'deep_cover/parser_ext'

  # Main
  require_relative_dir 'deep_cover', except: %w[auto_run builtin_takeover]

  extend Base
  extend Config::Setter
end
DeepCover::GLOBAL_BINDING = binding
