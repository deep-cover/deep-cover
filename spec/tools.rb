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

def our_coverage(fn)
  DeepCover.start
  DeepCover.require fn
  DeepCover.coverage(fn)
end

