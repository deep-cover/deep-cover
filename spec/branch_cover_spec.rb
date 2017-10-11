require "spec_helper"

RSpec::Matchers.define :have_correct_branch_coverage do |filename, lineno|
  match do |lines|
    answers = DeepCover::Tools::parse_cov_comments_answers(lines)
    lines << "    'flow_completion check. (Must be red if previous raised, green otherwise)'"
    @covered_code = DeepCover::CoveredCode.new(path: filename, source: lines.join, lineno: lineno)

    reached_end = DeepCover::Tools.execute_sample(@covered_code)
    if reached_end
      answers[lines.size - 1] = DeepCover::Tools::FULLY_EXECUTED
    else
      answers[lines.size - 1] = DeepCover::Tools::NOT_EXECUTED
    end

    cov = @covered_code.branch_cover
    errors = cov.zip(answers, lines).each_with_index.reject do |(a, expected, line), i|
      actual = DeepCover::Tools.strip_when_unimportant(line, a)
      next true if line.strip =~ /^#[ >]/
      if expected.is_a?(Regexp)
        actual =~ expected
      else
        expected = DeepCover::Tools.strip_when_unimportant(line, expected).ljust(actual.size, ' ')
        actual == expected
      end
    end
    @errors = errors.map{|_, i| i + lineno}
    #binding.pry unless @errors.empty?
    @errors.empty?
  end
  failure_message do |fn|
    formatted_lines = DeepCover::Tools.format_branch_cover(@covered_code)
    formatted_lines = DeepCover::Tools.number_lines(formatted_lines, lineno: lineno, bad_linenos: @errors)
    "Branch cover does not match on lines #{@errors.join(', ')}\n#{formatted_lines.join("\n")}"
  end
end

RSpec.describe 'branch cover' do
  each_code_examples('./spec/branch_cover/*.rb', name: 'branch') do |fn, lines, lineno|
    lines.should have_correct_branch_coverage(fn, lineno)
  end

  it 'tests against at least one of every node types', pending: true do
    visited = Set.new
    Dir.glob('./spec/branch_cover/*.rb') do |filename|
      ast = DeepCover::CoveredCode.new(path: filename).covered_ast
      next unless ast
      ast.each_node do |node|
        visited << node.class
      end
    end

    all_node_classes = ObjectSpace.each_object(Class).select { |klass| klass < DeepCover::Node }
    unvisited_node_classes = all_node_classes - visited.to_a
    unvisited_node_classes.sort_by!(&:name)
    fail_msg = "Node classes without branch cover test:\n#{unvisited_node_classes.pretty_inspect}"
    unvisited_node_classes.should be_empty, fail_msg
  end

  it 'handles an empty file' do
    covered_code = DeepCover::CoveredCode.new(source: '')
    covered_code.execute_code
    expect { covered_code.branch_cover }.not_to raise_error
  end
end
