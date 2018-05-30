# frozen_string_literal: true

require 'fileutils'

require 'active_support/core_ext/object/blank'
class Array
  def trim_blank
    drop_while(&:blank?)
      .reverse.drop_while(&:blank?).reverse
  end
end

def clean_env_system(*args)
  Bundler.with_clean_env do
    system(*args)
  end
end

def dummy_method(*args)
  args.first
end

# Ruby sometimes remove code when literals are present
# Possibly removing entire conditions if the literal makes it obvious it won't run
# or just removing a single literal
def falsx
  false
end

# Ruby sometimes remove code when literals are present
# Possibly removing entire conditions if the literal makes it obvious it won't run
# or just removing a single literal
def trux
  true
end

def current_ast
  DeepCover::Specs.current_ast
end

def assert(check)
  raise 'assert failed' if check == false
  raise "bad assert, expected true/false, got #{check.inspect}" unless check == true
end

def assert_equal(expected, actual)
  raise "assert failed: expected #{expected.inspect}, actual: #{actual.inspect}" if expected != actual
end

def assert_counts(node_or_lookup, expected)
  expected = {flow_entry: expected, flow_completion: expected, execution: expected} unless expected.is_a? Hash
  node = node.is_a?(DeepCover::Node) ? node : current_ast[node_or_lookup]
  assert_equal expected, node.counts
end

module DeepCover
  class CoveredCode
    module CurrentExtension
      def execute_code(*)
        Specs.current_ast = covered_ast
        super
      end
    end
    prepend CurrentExtension
    # For now, when an overlap is found, just open a binding.pry to make fixing it easier.
    def check_node_overlap!
      node_to_positions = {}
      each_node do |node|
        node.proper_range.each do |position|
          if node_to_positions[position]
            already = node_to_positions[position]
            puts "There is a proper_range overlap between #{node} and #{already}"
            puts "Overlapping: #{already.proper_range & node.proper_range}"
            binding.pry
          end
          node_to_positions[position] = node
        end
      end
    end
  end

  module Specs
    ANSWER = /^#>/
    FULLY_EXECUTED = /^[ -]*$/
    NOT_EXECUTED = /^-*x[x-]*$/ # at least an 'x', maybe some -

    UNIMPORTANT_CHARACTERS = /\s/

    extend self
    attr_accessor :current_ast

    def parse_cov_comments_answers(lines)
      answers = []
      line_index = 0
      lines.chunk { |line| line !~ ANSWER }.each do |is_code, chunk|
        chunk.map!(&:chomp)
        unless is_code
          raise 'Hey' unless chunk.size == 1
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
      answers.map! { |a| a || FULLY_EXECUTED }
    end

    def strip_when_unimportant(code, data)
      data.chars.reject.with_index do |char, i|
        code[i] =~ UNIMPORTANT_CHARACTERS
      end.join
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
          raise 'Already have a pwd selected' if set_pwd
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
      def process_grouped_examples(lines, pattern, lineno = 1)
        chunks = lines.slice_before(pattern)
        chunks = chunks.map { |chunk| v = [chunk, lineno]; lineno += chunk.size; v }
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
