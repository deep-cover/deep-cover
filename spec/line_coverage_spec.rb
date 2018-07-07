# frozen_string_literal: true

require_relative 'spec_helper'
require 'tempfile'


RSpec::Matchers.define :have_correct_line_coverage do |filename, lines, lineno, allow_partial:|
  match do
    @our = DeepCover::Tools.our_coverage(lines.join, filename, lineno, allow_partial: allow_partial)
    answers = DeepCover::Specs.parse_cov_comments_answers(lines)

    errors = @our.zip(answers, lines).each_with_index.reject do |(cov, comment_answer, line), _i|
      expected_result?(cov, line, comment_answer)
    end
    @errors = errors.map { |_, i| i + lineno }
    @errors.empty?
  end
  failure_message do |fn|
    lines = DeepCover::Tools.format(@our, source: lines.join)
    result = DeepCover::Tools.number_lines(lines, lineno: lineno, bad_linenos: @errors).join
    "Line coverage does not match in #{File.absolute_path(filename)} on lines #{@errors.join(', ')}\n#{result}"
  end

  define_method :expected_result? do |cov, line, comment_answer|
    return cov == 0 if comment_answer == DeepCover::Specs::NOT_EXECUTED
    return true if line.strip =~ /^#[ >]/

    unless allow_partial
      return cov == 0 if line =~ /# missed_empty_branch/
    end

    return cov == nil || cov > 0 if comment_answer == DeepCover::Specs::FULLY_EXECUTED

    comment_answer = DeepCover::Specs.strip_when_unimportant(line, comment_answer)
    line = DeepCover::Specs.strip_when_unimportant(line, line)
    comment_answer += ' ' * [line.size - comment_answer.size, 0].max

    if [nil, false, :branch].include?(allow_partial)
      comment_answer.chars.zip(line.chars).each do |a, l|
        return cov == 0 if a == 'x' && l =~ /\S/
      end
    end

    comment_answer.chars.zip(line.chars).each do |a, l|
      return cov && cov > 0 if a == ' ' && l =~ /\S/
    end

    return cov == 0 if comment_answer.include?('x')
    return cov.nil? if comment_answer.include?('-')

    if line =~ /\S/
      cov && cov > 0
    else
      cov.nil?
    end
  end
end

RSpec.describe 'line coverage' do
  each_code_examples('./spec/char_cover/*.rb', name: 'line') do |fn, lines, lineno|
    should have_correct_line_coverage(fn, lines, lineno, allow_partial: true)
  end

  it 'handles an empty file' do
    covered_code = DeepCover::CoveredCode.new(source: '')
    covered_code.execute_code
    expect { covered_code.line_coverage }.not_to raise_error
  end
end

RSpec.describe 'strict line coverage' do
  each_code_examples('./spec/char_cover/*.rb', name: 'line_strict') do |fn, lines, lineno|
    # Node, the examples may need to have `# missed_empty_branch` added at the end of lines that
    # are marked as fully covered by the regular comments, but is a fork to a branch with an empty body
    should have_correct_line_coverage(fn, lines, lineno, allow_partial: false)
  end
end
