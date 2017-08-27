require "parser"
require "unparser"

require "deep_cover/version"
require "deep_cover/branch_cover"

module DeepCover

  extend self

  def rewrite(filename)
    cover         = BranchCover.new
    buffer = Parser::Source::Buffer.new(filename)
    cover.original_code = buffer.source = File.read(filename)
    parser        = Parser::CurrentRuby.new
    ast           = parser.parse(buffer)
    cover.covered_code = cover.rewrite(buffer, ast)
    cover
  end
end
