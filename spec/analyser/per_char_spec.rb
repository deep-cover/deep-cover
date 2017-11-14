# frozen_string_literal: true

require 'spec_helper'

module DeepCover
  RSpec.describe Analyser::PerChar do
    let(:code) { <<-RUBY }
      def foo(a = 1234)
        raise unless a >= 42
      end
      foo(100)
      RUBY
    let(:node) { Node[code] }
    let(:analyser) do
      Analyser::PerChar.new(node, ignore_uncovered: :default_argument)
    end
    let(:stats) { analyser.stats }

    it 'gives good stats' do
      stats.to_h.should == {
                             executed: 3 + 3 + 6 + 5 + 3 + 3,
                             not_executed: 5, # raise
                             ignored: 4, # 1234
                             not_executable: 46,
                           }
      stats.total.should == code.length
    end
  end
end
