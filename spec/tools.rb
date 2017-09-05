require 'coverage'

CONVERT = Hash.new('  ')
CONVERT[0] = 'x '
CONVERT[nil] = '- '

def format(fn, *results)
  code =  File.read(fn)
  lines = code.lines
  results.map!{|counts| counts.map{|c| CONVERT[c]}}
  [*results, code.lines]
    .transpose
    .map(&:join)
end

def builtin_coverage(fn)
  fn = File.expand_path(fn)
  Coverage.start
  require fn
  Coverage.result.fetch(fn)
end

def branch_coverage(fn)
  DeepCover.start
  DeepCover.require fn
  DeepCover.branch_coverage(fn)
end

def our_coverage(fn)
  DeepCover.start
  DeepCover.require fn
  DeepCover.line_coverage(fn)
end

COLOR = {'x' => :red, ' ' => :green, '-' => :faint}
def format_branch_cover(context)
  bc = context.branch_cover
  require 'term/ansicolor'
  context.buffer.source_lines.map.with_index do |line, line_index|
    line.chars.map.with_index do |c, c_index|
      color = COLOR[bc[line_index][c_index]]
      Term::ANSIColor.send(color, c)
    end.join
  end
end
