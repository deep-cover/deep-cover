require "parser"
require "unparser"

require "deep_cover/version"
require "deep_cover/branch_cover"

module DeepCover
  extend self

  def rewrite(filename)
    code = File.read(filename)
    buffer = Parser::Source::Buffer.new(filename)
    buffer.source = code
    parser        = Parser::CurrentRuby.new
    ast           = parser.parse(buffer)
    rewriter      = BranchCover.new
    coverred_code = rewriter.rewrite(buffer, ast)

    puts ast
    puts coverred_code

    coverred_code
  end
end
