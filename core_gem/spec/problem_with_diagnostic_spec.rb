# frozen_string_literal: true

require_relative 'spec_helper'

module DeepCover
  RSpec.describe ProblemWithDiagnostic do
    let(:code) { <<-RUBY }
      # The first few lines will be truncated
      dummy_method 2
      dummy_method 3
      dummy_method 4
      dummy_method 5
      dummy_method 6
      # ...
      dummy_method 42
      #
      if 666
        'hello'
      else
        'world'
      end
      #
      dummy_method -1
    RUBY
    let(:node) { Node[code][:if] }
    let(:covered_code) { node.covered_code }
    let(:line_range) { node.diagnostic_expression }
    let(:original_exception) { begin; raise 'Bogus exception'; rescue Exception => e; e; end }
    let(:problem) { ProblemWithDiagnostic.new(covered_code, line_range, original_exception) }

    describe :message do
      it 'returns a very informative message' do
        expect(covered_code).to receive(:path).and_return('some/bogus/path.rb')

        Term::ANSIColor.uncolor(problem.message).should == <<-MESSAGE.strip
You found a problem with DeepCover!
Please open an issue at https://github.com/deep-cover/deep-cover/issues
and include the following diagnostic information:
| Source file: some/bogus/path.rb
| Line numbers: 10..14
| Source lines around location:
|      3 |       dummy_method 3
|      4 |       dummy_method 4
|      5 |       dummy_method 5
|      6 |       dummy_method 6
|      7 |       # ...
|      8 |       dummy_method 42
|      9 |       #
|    *10 |       if 666
|    *11 |         'hello'
|    *12 |       else
|    *13 |         'world'
|    *14 |       end
|     15 |       #
|     16 |       dummy_method -1
| Original exception:
|   RuntimeError: Bogus exception
#{original_exception.backtrace.map { |t| "|     #{t}" }.join("\n")}
        MESSAGE
      end
    end
  end
end
