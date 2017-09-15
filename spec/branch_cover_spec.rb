require "spec_helper"

ANSWER = /^#>/
FULLY_EXECUTED = /^[ -]*$/
NOT_EXECUTED = /^-*x[x-]*$/ # at least an 'x', maybe some -
UNIMPORTANT_CHARACTERS = /[ \t();,]/

def parse(lines, lineno)
  code = []
  answers = []
  lines.chunk{|line| line !~ ANSWER}.each do |is_code, chunk|
    chunk.map!(&:chomp)
    code.concat(chunk)
    unless is_code
      raise "Hey" unless chunk.size == 1
      answer = chunk.first
      if answer.start_with?('#>X')
        answer = NOT_EXECUTED
      else
        answer = "  #{answer[2..-1]}"
      end
      answers[code.size - 2] = answer
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

RSpec::Matchers.define :have_correct_branch_coverage do |filename, lineno|
  match do |lines|
    code, answers = parse(lines, lineno)
    @file_coverage = DeepCover::FileCoverage.new(path: filename, source: code.join("\n"), lineno: lineno)
    @file_coverage.execute_file
    cov = @file_coverage.branch_cover
    errors = cov.zip(answers, code).each_with_index.reject do |(a, expected, line), i|
      actual = strip_when_unimportant(line, a)
      actual = ' ' * actual.size if line.strip.start_with?('#>')
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
    formatted_branch_cover = DeepCover::Tools.format_branch_cover(@file_coverage, show_line_nbs: true)
    "Branch cover does not match on lines #{@errors.join(', ')}\n#{formatted_branch_cover.join("\n")}"
  end
end

RSpec.describe 'branch cover' do
  Dir.glob('./spec/branch_cover/*.rb').each do |fn|
    describe File.basename(fn, '.rb') do
      example_groups = DeepCover::Tools::AnnotatedExamplesParser.process(File.read(fn).lines)
      example_groups.each do |section, examples|
        context(section || '(General)') do
          examples.each do |title, (lines, lineno)|
            msg = case [section, title].join
            when /\(pending/i then :pending
            when /\(Ruby 2\.(\d)/i
              :skip if RUBY_VERSION < "2.#{$1}.0"
            end
            send(msg || :it, title) { lines.should have_correct_branch_coverage(fn, lineno) }
          end
        end
      end
    end
  end
end
