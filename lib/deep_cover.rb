require "parser"
require_relative "deep_cover/misc"
module DeepCover

  Misc.require_relative_dir 'deep_cover/parser_ext'
  Misc.require_relative_dir 'deep_cover', except: %w[auto_run builtin_takeover]

  extend Base
  extend Config::Setter
end
DeepCover::GLOBAL_BINDING = binding
