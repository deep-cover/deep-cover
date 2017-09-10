require 'coverage'

def dummy_method(*)
end

module DeepCover
  module Tools
    CONVERT = Hash.new('  ')
    CONVERT[0] = 'x '
    CONVERT[nil] = '- '

    extend self

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
      ::Coverage.start
      require fn
      ::Coverage.result.fetch(fn)
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
    WHITESPACE_MAP = Hash.new{|_, v| v}.merge!(' ' => '·', "\t" => '→ ')
    def format_branch_cover(context, show_line_nbs: false, show_whitespace: false)
      bc = context.branch_cover
      require 'term/ansicolor'
      context.buffer.source_lines.map.with_index do |line, line_index|
        prefix = show_line_nbs ? Term::ANSIColor.faint((line_index+1).to_s.rjust(2) << ' | ') : ''
        prefix << line.chars.map.with_index do |c, c_index|
          color = COLOR[bc[line_index][c_index]]
          c = WHITESPACE_MAP[c] if show_whitespace
          Term::ANSIColor.send(color, c)
        end.join
      end
    end
  end
end
