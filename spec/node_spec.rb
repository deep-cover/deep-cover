require "spec_helper"

module DeepCover
  RSpec.describe Node do
    let(:code) { "dummy_method 42 || 'hello' if 666" }
    let(:node) { Node[code] }

    describe :find do
      it { node.find_all(Node::Int).map(&:value).should =~ [42, 666] }
      it { node.find_all(Node::Float).should == [] }
      it { node.find_all(:str).map(&:value) == ['hello'] }
      it { node.find_all("42 || 'hello'").map(&:class) == [Node::Or] }
      it { node.find_all(/^'hel/).map(&:value) == ['hello'] }
    end
  end
end
