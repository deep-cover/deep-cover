module DeepCover
  require 'parser'
  require_relative 'deep_cover/tools'
  require_relative_dir 'deep_cover/parser_ext'
  require_relative_dir 'deep_cover', except: %w[auto_run builtin_takeover]

  extend Base
  extend Config::Setter
end
DeepCover::GLOBAL_BINDING = binding
