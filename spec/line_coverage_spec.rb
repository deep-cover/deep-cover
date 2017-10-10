require "spec_helper"
require "tempfile"


RSpec::Matchers.define :have_correct_line_coverage do |filename, lines, lineno|
  match do
    @our = DeepCover::Tools.our_coverage(lines.join, filename, lineno)
    answers = DeepCover::Tools::parse_cov_comments_answers(lines)

    errors = @our.zip(answers, lines).each_with_index.reject do |(cov, comment_answer, line), _i|
      expected_result?(cov, line, comment_answer)
    end
    @errors = errors.map{|_, i| i + lineno}
    @errors.empty?
  end
  failure_message do |fn|
    lines = DeepCover::Tools.format(@our, source: lines.join)
    result = DeepCover::Tools.number_lines(lines, lineno: lineno, bad_linenos: @errors).join
    "Line coverage does not match on lines #{@errors.join(', ')}\n#{result}"
  end

  def expected_result?(cov, line, comment_answer)
    return cov == 0 if comment_answer == DeepCover::Tools::NOT_EXECUTED
    return true if line.strip.start_with?("#")

    if comment_answer.is_a?(String)
      comment_answer = DeepCover::Tools.strip_when_unimportant(line, comment_answer)
      line = DeepCover::Tools.strip_when_unimportant(line, line)
      comment_answer = comment_answer + " " * [line.size - comment_answer.size, 0].max
      comment_answer.chars.zip(line.chars).each do |a, l|
        return true if a == ' ' && l =~ /\S/
      end

      return cov == 0 if comment_answer.include?('x')
      return cov.nil? if comment_answer.include?('-')
    else
      line = DeepCover::Tools.strip_when_unimportant(line, line)
    end

    if line =~ /\S/
      cov && cov > 0
    else
      cov.nil?
    end
  end
end

RSpec.describe 'line coverage' do
  each_code_examples('./spec/branch_cover/*.rb') do |fn, lines, lineno|
    should have_correct_line_coverage(fn, lines, lineno)
  end

  it 'handles an empty file' do
    covered_code = DeepCover::CoveredCode.new(source: '')
    covered_code.execute_code
    expect { covered_code.line_coverage }.not_to raise_error
  end
end
