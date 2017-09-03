require "spec_helper"

module DeepCover
  RSpec.describe Node do
    describe :factory do
      it { Node.factory(:if ).should eq Node::If }
      it { Node.factory(:int).should eq Node::Literal }
      it { Node.factory(:foo).should eq Node }
    end
  end
end
