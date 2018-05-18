# frozen_string_literal: true

require 'spec_helper'

RSpec::Matchers.define :have_correct_char_coverage do |filename, lineno|
  def autofix(filename, answer, line, lineno)
    line.chomp.each_char.with_index do |c, i|
      answer[i] = ' ' if answer[i] == '-' && c =~ DeepCover::Specs::UNIMPORTANT_CHARACTERS
    end
    lines = File.read(filename).lines
    lines[lineno] = "#>  #{answer[4..-1].rstrip}\n"
    File.write(filename, lines.join)
  end

  match do |lines|
    answers = DeepCover::Specs.parse_cov_comments_answers(lines)
    lines << "    'flow_completion check. (Must be red if previous raised, green otherwise)'"
    @covered_code = DeepCover::CoveredCode.new(path: filename, source: lines.join, lineno: lineno)

    reached_end = DeepCover::Tools.execute_sample(@covered_code)
    if reached_end
      answers[lines.size - 1] = DeepCover::Specs::FULLY_EXECUTED
    else
      answers[lines.size - 1] = DeepCover::Specs::NOT_EXECUTED
    end
    @covered_code.check_node_overlap!
    cov = @covered_code.char_cover
    errors = cov.zip(answers, lines).each_with_index.reject do |(a, expected, line), i|
      actual = DeepCover::Specs.strip_when_unimportant(line, a)
      next true if line.strip =~ /^#[ >]/
      if expected.is_a?(Regexp)
        actual =~ expected
      else
        expected = DeepCover::Specs.strip_when_unimportant(line, expected).ljust(actual.size, ' ')
        ok = actual == expected
        autofix(filename, a, line, i + lineno) if ENV['FIX'] && !ok
        ok
      end
    end
    @errors = errors.map { |_, i| i + lineno }
    # binding.pry unless @errors.empty?
    @errors.empty?
  end
  failure_message do |fn|
    formatted_lines = DeepCover::Tools.format_char_cover(@covered_code)
    formatted_lines = DeepCover::Tools.number_lines(formatted_lines, lineno: lineno, bad_linenos: @errors)
    "Branch cover does not match on lines #{@errors.join(', ')}\n#{formatted_lines.join("\n")}"
  end
end

RSpec.describe 'char cover' do
  each_code_examples('./spec/char_cover/*.rb', name: 'char') do |fn, lines, lineno|
    lines.should have_correct_char_coverage(fn, lineno)
  end

  it 'tests against at least one of every node types', :pending, :slow do
    visited = Set.new
    Dir.glob('./spec/char_cover/*.rb') do |filename|
      ast = DeepCover::CoveredCode.new(path: filename).covered_ast
      ast.each_node do |node|
        visited << node.class
      end
    end

    unvisited_node_classes = DeepCover::Node::CLASSES - visited.to_a
    unvisited_node_classes.sort_by!(&:name)
    fail_msg = "Node classes without char cover test:\n#{unvisited_node_classes.pretty_inspect}"
    unvisited_node_classes.should be_empty, fail_msg
  end

  it 'handles an empty file' do
    covered_code = DeepCover::CoveredCode.new(source: '')
    covered_code.execute_code
    expect { covered_code.char_cover }.not_to raise_error
  end
end
