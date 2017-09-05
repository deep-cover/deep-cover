require "spec_helper"

SECTION = /^### (.*)$/
EXAMPLE = /^#### (.*)$/
ANSWER = /^#>/
FULLY_EXECUTED = /^[ -]*$/
NOT_EXECUTED = /^[ -]*[x-]+$/
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

RSpec::Matchers.define :have_correct_branch_coverage do
  match do |lines|
    lines = lines.trim_blank
    code, answers = parse(lines)
    @context = DeepCover::Context.new(source: code.join("\n"))
    cov = @context.branch_cover
    errors = cov.zip(answers).each_with_index.reject do |(actual, expected), i|
      if expected.is_a?(Regexp)
        actual =~ expected
      else
        (actual == expected) ||
          code[i].chars.each_with_index.all? do |char, i|
            (char =~ UNIMPORTANT_CHARACTERS) ||
            actual[i] == (expected[i] || ' ')
          end
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

def check(lines)
  lines.should have_correct_branch_coverage
end

module BranchCoverHelpers
  # Breaks the lines of code into sub sections and sub tests
  def process_grouped_examples(lines, pattern )
    lines
      .slice_before(pattern)
      .map(&:trim_blank)
      .compact
      .each { |lines_chunk| process_example(lines_chunk) }
  end

  def process_example(lines)
    case lines.first
    when SECTION
      context($1) { process_grouped_examples(lines.drop(1), EXAMPLE) }
    when EXAMPLE
      it($1) { check(lines.drop(1)) }
    else
      it { check(lines) }
    end
  end
end

class RSpec::Core::ExampleGroup
  extend BranchCoverHelpers
end

RSpec.describe 'branch cover' do
  Dir.glob('./spec/branch_cover/*.rb').each do |fn|
    describe File.basename(fn, '.rb') do
      process_grouped_examples(File.read(fn).lines, SECTION)
    end
  end
end
