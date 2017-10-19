require "spec_helper"
require 'backports/2.4.0/hash/transform_values'

module DeepCover
  RSpec.describe Analyser::Statement do
    let(:analyser) {
      Analyser::Statement.new(node)
    }
    let(:results) { analyser.results }
    let(:by_execution) do
      results
        .sort_by{|range, _runs| range.begin_pos }
        .group_by{|_range, runs| runs != 0 }
        .transform_values{|ranges_run_pairs| ranges_run_pairs.map(&:first)}
    end
    let(:lines_by_execution) { by_execution.transform_values{|ranges| ranges.map(&:line)} }
    let(:columns_by_execution) { by_execution.transform_values{|ranges| ranges.map{|r| r.begin_pos ... r.end_pos}} }
    subject { lines_by_execution }

    context 'With multiple expression in a line' do
      let(:node){ Node[ <<-RUBY ] }
        1 + 1; 2 + 2 == 4; :bye
      RUBY
      it 'returns the right ranges' do
        columns_by_execution.should == {true => [8...13, 15...25, 27...31]}
      end
    end

    context 'With expressions on different lines' do
      let(:node){ Node[<<-RUBY] }
        if false
          1
          :a
        end
        dummy_method('x') || []
        RUBY

      it { should == {false => [2, 3], true => [1, 5]} }
    end

    context 'With unexecuted subexpressions' do
      let(:node){ Node[<<-RUBY] }
        dummy_method(
          'x' ||
          42
        )
        RUBY
      it { should == {false => [3], true => [1]} }
    end

    context 'With unexecuted subexpressions' do
      let(:node){ Node[<<-RUBY] }
        if true
          dummy_method(
            42,
            raise,
            42
          )
        end rescue false
        RUBY
      xit { should == {false => [2, 5], true => [1, 3, 4, 7]} }
    end

    context 'With modules and defs' do
      let(:node){ Node[<<-RUBY] }
        module M
          module N
            def foo
              42
            end
          end
          def bar
            42
          end
          extend self
        end
        M.bar
        RUBY
      it { should == {false => [4], true => [1, 2, 3, 7, 8, 10, 12]} }
    end

    context 'With comments' do
      let(:node){ Node[<<-RUBY] }
        module M
          def bar; end
          # a comment
          def baz; end
        end
        RUBY
      it { should == {true => [1, 2, 4]} }
    end
  end
end
