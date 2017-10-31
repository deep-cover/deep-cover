require "spec_helper"

module DeepCover
  RSpec.describe Analyser::Branch do
    def line(node)
      node.expression.line rescue binding.pry
    end

    let(:options) { {} }
    let(:analyser) {
      Analyser::Branch.new(node, **options)
    }
    let(:results) { analyser.results }
    let(:line_runs) { results.map do |node, branches_runs|
        [line(node), branches_runs.map do |branch, runs|
          [line(branch), runs != 0]
        end.to_h]
      end.to_h
    }

    context 'for a if' do
      let(:node){ Node[ <<-RUBY ] }
        if false
          raise
        else
          "yay"
        end
      RUBY
      it { line_runs.should == {1 => {2 => false, 4 => true}} }

      context 'when ignoring trivial ifs' do
        let(:options) { {ignore_uncovered: :trivial_if} }
        it { line_runs.should == {1 => {2 => true, 4 => true}} }
      end
    end
  end
end
