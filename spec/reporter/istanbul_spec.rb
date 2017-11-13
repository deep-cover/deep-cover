# frozen_string_literal: true

require 'spec_helper'
require 'deep_cover/reporter/istanbul'

module DeepCover
  module Reporter
    RSpec.describe Istanbul do
      let(:covered_code){ Node[source].covered_code }
      let(:options) { {} }
      let(:reporter) { Istanbul.new(covered_code, **options) }
      subject { reporter.report }

      context 'given a simple code code' do
        let(:source) { <<-RUBY }
          dummy_method('example')
          if(false)
            dummy_method('example')
          end
          RUBY
        it { should =~ /"statementMap":/ }
        it { should =~ /"s":/ }
        it { should include '"b":{"1":[0,1]}' }
      end
    end

    RSpec.describe Istanbul::Converters do
      include Istanbul::Converters
      let(:def_node)   { Node[<<-RUBY] }
        # an example.
        def foo(arg = 42)
          dummy_method
        end
        RUBY
      let(:branch_node)   { Node[<<-RUBY] }
        if false
          :foo
        else
          :bar
        end
        RUBY
      let(:def_node_no_args)    { Node['def foo;end'] }
      let(:block_node)          { Node['1.times { |arg = 42| dummy_method }'] }
      let(:lambda_node)         { Node['->(arg = 42) { dummy_method }'] }
      let(:block_node_no_args)  { Node['1.times { }'] }
      let(:pos)        { def_node.loc_hash[:name] }

      it 'converts ranges' do
        convert_range(pos).should == {
          start: {line: 2, column: 12},
          end:   {line: 2, column: 14}
        }
      end

      it 'converts lists' do
        convert_list([:a, :b, :c]).should == {'1' => :a, '2' => :b, '3' => :c}
      end

      it 'converts def nodes' do
        convert_def(def_node).should == {
          name: :foo,
          line: 2,
          decl: {start: {line: 2, column:  8}, end: {line: 2, column: 24}},
          loc:  {start: {line: 3, column: 10}, end: {line: 3, column: 21}},
        }
      end

      it 'converts trivial def nodes' do
        convert_def(def_node_no_args)[:decl].should == {
          start: {line: 1, column: 0}, end: {line: 1, column: 6},
        }
      end

      it 'converts block nodes' do
        convert_block(block_node).should == {
          name: '(block)',
          line: 1,
          decl: {start: {line: 1, column: 8}, end: {line: 1, column: 19}},
          loc:  {start: {line: 1, column: 21}, end: {line: 1, column: 32}},
        }
      end

      it 'converts lambdas' do
        convert_block(lambda_node).should == {
          name: '(block)',
          line: 1,
          decl: {start: {line: 1, column: 2}, end: {line: 1, column: 13}},
          loc:  {start: {line: 1, column: 15}, end: {line: 1, column: 26}},
        }
      end

      it 'converts trivial block nodes' do
        convert_block(block_node_no_args)[:decl].should == {
          start: {line: 1, column: 8}, end: {line: 1, column: 8},
        }
      end

      # Subject to change; istanbul seems to output the same location for loc & locations...
      it 'converts branches' do
        convert_branch(branch_node).should == {
          line: 1,
          type: :if,
          loc: {start: {line: 1, column:  8}, end: {line: 5, column: 10}},
          locations: [
            {start: {line: 2, column:  10}, end: {line: 2, column: 13}},
            {start: {line: 4, column:  10}, end: {line: 4, column: 13}},
          ],
        }
      end
    end
  end
end
