require "spec_helper"

SECTION = /^### (.*)$/
EXAMPLE = /^#### (.*)$/
ANSWER = /^#>/
FULLY_EXECUTED = /^[ -]*$/
NOT_EXECUTED = /^-*x[x-]*$/ # at least an 'x', maybe some -
UNIMPORTANT_CHARACTERS = /[ \t();,]/

def parse(lines)
  code = []
  answers = []
  lines.chunk{|line| line !~ ANSWER}.each do |is_code, chunk|
    chunk.map!{|line| line[2..-1] || ''}.map!(&:chomp)
    if is_code
      code.concat(chunk)
    else
      raise "Hey" unless chunk.size == 1
      answer = chunk.first
      answer = NOT_EXECUTED if answer == 'X'
      answers[code.size-1] = answer
    end
  end
  answers[code.size] ||= nil
  answers.map!{|a| a || FULLY_EXECUTED }
  [code, answers]
end

def strip_when_unimportant(code, data)
  data.chars.reject.with_index do |char, i|
    code[i] =~ UNIMPORTANT_CHARACTERS
  end.join
end

RSpec::Matchers.define :have_correct_branch_coverage do
  match do |lines|
    lines = lines.trim_blank
    code, answers = parse(lines)
    @context = DeepCover::Context.new(source: code.join("\n"))
    cov = @context.branch_cover
    errors = cov.zip(answers, code).each_with_index.reject do |(a, expected, line), i|
      actual = strip_when_unimportant(line, a)
      if expected.is_a?(Regexp)
        actual =~ expected
      else
        expected = strip_when_unimportant(line, expected).ljust(actual.size, ' ')
        actual == expected
      end
    end
    @errors = errors.map{|_, i| i + 1}
    @errors.empty?
  end
  failure_message do |fn|
    puts format_branch_cover(@context, show_line_nbs: true)
    "Branch cover does not match on lines #{@errors.join(', ')}"
  end
end

class AnnotatedExamplesParser
  def self.process(lines)
    new.process_grouped_examples(lines, SECTION).example_groups
  end

  attr_reader :example_groups
  def initialize
    @example_groups = {}
    @section = nil
  end

  # Breaks the lines of code into sub sections and sub tests
  def process_grouped_examples(lines, pattern )
    lines
      .slice_before(pattern)
      .map(&:trim_blank)
      .compact
      .each { |lines_chunk| process_example(lines_chunk) }
    self
  end

  def process_example(lines)
    case lines.first
    when SECTION
      @section = $1
      process_grouped_examples(lines.drop(1), EXAMPLE)
    when EXAMPLE
      group[$1] = lines.drop(1)
    else
      group[nil] = lines
    end
  end

  def group
    @example_groups[@section] ||= {}
  end
end

RSpec.describe 'branch cover' do
  Dir.glob('./spec/branch_cover/*.rb').each do |fn|
    describe File.basename(fn, '.rb') do
      example_groups = AnnotatedExamplesParser.process(File.read(fn).lines)
      example_groups.each do |section, examples|
        context(section || '(General)') do
          examples.each do |title, lines|
            it(title) { lines.should have_correct_branch_coverage }
          end
        end
      end
    end
  end
end
