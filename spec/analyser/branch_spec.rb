require "spec_helper"

module DeepCover
  RSpec.describe Analyser::Branch do
    def map(results)
      results.map do |node, branches_runs|
        [yield(node), branches_runs.map do |branch, runs|
          [yield(branch), runs]
        end.to_h]
      end.to_h
    end

    let(:options) { {} }
    let(:analyser) {
      Analyser::Branch.new(node, **options)
    }
    let(:results) { analyser.results }
    let(:line_runs) { map(results){|node| node.expression.line } }
    let(:type_runs) { map(results, &:type) }

    context 'for a if' do
      let(:node){ Node[ <<-RUBY ] }
        if false
          raise
        else
          "yay"
        end
      RUBY
      it { line_runs.should == {1 => {2 => 0, 4 => 1}} }
      it { type_runs.should == {if: {send: 0, str: 1}} }

      context 'when ignoring trivial ifs' do
        let(:options) { {ignore_uncovered: :trivial_if} }
        it { line_runs.should == {1 => {2 => nil, 4 => 1}} }
        it { type_runs.should == {if: {send: nil, str: 1}} }
      end

      context 'without an else' do
        let(:node){ Node['42 if false'] }
        it { type_runs.should == {if: {int: 0, EmptyBody: 1}} }
      end
    end

    context 'for the safe navigation' do
      let(:node){ Node['nil&.foo'] }
      it { type_runs.should == {csend: {safe_send: 0, EmptyBody: 1}} }
    end unless RUBY_VERSION < '2.3'

  end
end
