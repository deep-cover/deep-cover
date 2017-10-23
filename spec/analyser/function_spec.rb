require "spec_helper"

module DeepCover
  RSpec.describe Analyser::Function do
    let(:analyser) {
      Analyser::Function.new(node)
    }
    let(:results) { analyser.results }

    context 'for defs' do
      let(:node){ Node[<<-RUBY] }
        def foo
        end
        def bar
        end
        foo; foo
        RUBY
      let(:name_runs) { results.map{|node, runs| [node.method_name, runs]}.to_h }

      it { name_runs.should == {foo: 2, bar: 0} }
    end

    context 'for blocks' do
      let(:node){ Node[<<-RUBY] }
        42.times{}
        loop{} if false
        RUBY
      it { results.values.should == [42, 0] }
    end
  end
end
