require 'coverage'
require 'term/ansicolor'

require 'active_support/core_ext/object/blank'
class Array
  def trim_blank
    drop_while(&:blank?)
      .reverse.drop_while(&:blank?).reverse
  end
end

def dummy_method(*)
end

def with_warnings(flag)
  old_verbose, $VERBOSE = $VERBOSE, flag
  yield
ensure
  $VERBOSE = old_verbose
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

    def format_generated_code(file_coverage)
      inserts = []
      generated_code = file_coverage.rewrite_source do |inserted, _node, expr_limit|
        inserts << [expr_limit, inserted.size]
        Term::ANSIColor.yellow(inserted)
      end

      inserts = inserts.sort_by{|exp, _| [exp.line, exp.column]}.reverse
      generated_lines = generated_code.split("\n")

      inserts.each do |exp_limit, size|
        # Line index starts at 1, so array index returns the next line
        comment_line = generated_lines[exp_limit.line]
        next unless comment_line.present?
        next unless comment_line.start_with?('#>')
        next if comment_line.start_with?('#>X')
        next unless comment_line.size >= exp_limit.column
        comment_line.insert(exp_limit.column, ' ' * size) rescue binding.pry
      end
      generated_lines.join("\n")
    end

    COLOR = {'x' => :red, ' ' => :green, '-' => :faint}
    WHITESPACE_MAP = Hash.new{|_, v| v}.merge!(' ' => '·', "\t" => '→ ')
    def format_branch_cover(file_coverage, show_line_nbs: false, show_whitespace: false)
      bc = file_coverage.branch_cover

      file_coverage.buffer.source_lines.map.with_index do |line, line_index|
        prefix = show_line_nbs ? Term::ANSIColor.faint((line_index+1).to_s.rjust(2) << ' | ') : ''
        next prefix + line if line.strip.start_with?("#")
        prefix << line.chars.map.with_index do |c, c_index|
          color = COLOR[bc[line_index][c_index]]
          c = WHITESPACE_MAP[c] if show_whitespace
          Term::ANSIColor.send(color, c)
        end.join
      end
    end

    class AnnotatedExamplesParser
      SECTION = /^### (.*)$/
      EXAMPLE = /^#### (.*)$/

      def self.process(lines)
        lines = lines.lines if lines.is_a?(String)
        new.process_grouped_examples(lines, SECTION).example_groups
      end

      attr_reader :example_groups
      def initialize
        @example_groups = {}
        @section = nil
      end

      # Breaks the lines of code into sub sections and sub tests
      def process_grouped_examples(lines, pattern, lineno=1)
        chunks = lines.slice_before(pattern)
        chunks = chunks.map{|chunk| v = [chunk, lineno]; lineno += chunk.size; v }
        chunks.map do |chunk, chunk_lineno|
          trimmed_chunk = chunk.trim_blank
          [trimmed_chunk, chunk_lineno + chunk.index(trimmed_chunk.first)]
        end
        chunks.each { |chunk, chunk_lineno| process_example(chunk, chunk_lineno) }
        self
      end

      def process_example(lines, lineno)
        first = lines.first
        if first =~ SECTION
          @section = $1
          process_grouped_examples(lines.drop(1), EXAMPLE, lineno + 1)
        else
          if first =~ EXAMPLE
            trimmed_lines = lines.drop(1).trim_blank
            lineno = lineno + lines.index(trimmed_lines.first)
            lines = trimmed_lines
          end
          group[$1] = [lines, lineno]
        end
      end

      def group
        @example_groups[@section] ||= {}
      end
    end
  end
end
