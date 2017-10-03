require 'coverage'
require 'term/ansicolor'
require 'fileutils'
require 'tmpdir'

require 'active_support/core_ext/object/blank'
class Array
  def trim_blank
    drop_while(&:blank?)
      .reverse.drop_while(&:blank?).reverse
  end
end

def dummy_method(*)
end

module DeepCover
  module Tools
    ANSWER = /^#>/
    FULLY_EXECUTED = /^(-* [ -]*|)$/
    NOT_EXECUTED = /^-*x[x-]*$/ # at least an 'x', maybe some -

    CONVERT = Hash.new('  ')
    CONVERT[0] = 'x '
    CONVERT[nil] = '- '

    extend self

    def format(*results, filename: nil, source: nil, lineno: 1, bad_linenos: [])
      source ||= File.read(filename)
      results.map!{|counts| counts.map{|c| CONVERT[c]}}
      [*results, source.lines].transpose.each_with_index.map do |parts, i|
        *line_results, line = parts
        if bad_linenos.include?(lineno + i)
          line_s = Term::ANSIColor.red("#{lineno + i}| ")
        else
          line_s = Term::ANSIColor.white("#{lineno + i}| ")
        end
        next line_s + parts.join if line_results.size <= 1

        if line_results.all?{|res| res == line_results[0]}
          line_s + Term::ANSIColor.green(line_results.join) + line.to_s
        else
          line_s + Term::ANSIColor.yellow(line_results.join) + line.to_s
        end
      end
    end

    def builtin_coverage(source, fn, lineno)
      fn = File.absolute_path(File.expand_path(fn))
      ::Coverage.start
      execute_sample ->{ DeepCover::Misc.compile(source, fn, fn, lineno).eval}
      ::Coverage.result.fetch(fn)[(lineno-1)..-1]
    end

    def our_coverage(source, fn, lineno, **options)
      covered_code = DeepCover::CoveredCode.new(source:source, path: fn, lineno: lineno)
      execute_sample(covered_code)
      covered_code.line_coverage(options)
    end

    def format_generated_code(covered_code)
      inserts = []
      generated_code = covered_code.instrument_source do |inserted, _node, expr_limit|
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
    def format_branch_cover(covered_code, show_line_nbs: false, show_whitespace: false, lineno: 1)
      bc = covered_code.branch_cover

      covered_code.buffer.source_lines.map.with_index do |line, line_index|
        prefix = show_line_nbs ? Term::ANSIColor.faint((line_index+lineno).to_s.rjust(2) << ' | ') : ''
        next prefix + line if line.strip.start_with?("#")
        prefix << line.chars.map.with_index do |c, c_index|
          color = COLOR[bc[line_index][c_index]]
          c = WHITESPACE_MAP[c] if show_whitespace
          Term::ANSIColor.send(color, c)
        end.join
      end
    end

    def parse_cov_comments_answers(lines)
      answers = []
      line_index = 0
      lines.chunk{|line| line !~ ANSWER}.each_with_index do |(is_code, chunk)|
        chunk.map!(&:chomp)
        unless is_code
          raise "Hey" unless chunk.size == 1
          answer = chunk.first
          if answer.start_with?('#>X')
            answer = NOT_EXECUTED
          else
            answer = "  #{answer[2..-1]}"
          end
          answers[line_index - 1] = answer
        end
        line_index += chunk.size
      end
      answers[lines.size] ||= nil
      answers.map!{|a| a || FULLY_EXECUTED }
    end

    # Creates a tree of directories and files for testing.
    # This is meant to be used within `Dir.mktmpdir`
    # The tree_content is an array of paths.
    # * Each entry can be as deep as needed, intermediary directories will be created.
    # * Finish an entry with a / for the last part to also be a directory.
    # * Start an entry with "pwd:" and the current working directory will be set there.
    # * if a file ends with .rb, it will contain code to set $last_test_tree_file_executed to the entry (without pwd:)
    def file_tree(root, tree_contents)
      set_pwd = nil
      tree_contents.each do |tree_entry|
        if tree_entry.start_with?('pwd:')
          raise "Already have a pwd selected" if set_pwd
          tree_entry = tree_entry.sub(/^pwd:/, '')
          raise "#{tree_entry} is not a directory entry (must end with /), can't use as pwd" unless tree_entry.end_with?('/')
          set_pwd = true # Set later
        end

        # Avoid a simple mistake
        tree_entry = tree_entry[1..-1] if tree_entry[0] == '/'

        path = File.absolute_path(tree_entry, root)
        set_pwd = path if set_pwd == true

        if tree_entry.end_with?('/')
          FileUtils.mkdir_p(path)
        else
          FileUtils.mkdir_p(File.dirname(path))
          content = <<-RUBY if tree_entry.end_with?('.rb')
            $last_test_tree_file_executed = #{tree_entry.inspect}
          RUBY
          File.write(path, content)
        end
      end

      Dir.chdir(set_pwd || '.')
    end

    # Returns true if the code would have continued, false if the rescue was triggered.
    def execute_sample(to_execute)
      # Disable some annoying warning by ruby. We are testing edge cases, so warnings are to be expected.
      begin
        DeepCover::Misc.with_warnings(nil) do
          if to_execute.is_a?(CoveredCode)
            to_execute.execute_code
          else
            to_execute.call
          end
        end
        true
      rescue RuntimeError => e
        raise unless e.message.empty?
        false
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
