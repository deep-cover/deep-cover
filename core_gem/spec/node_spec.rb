# frozen_string_literal: true

require_relative 'spec_helper'

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

    describe :[] do
      it { node[1].should equal node.children[1] }
      it { expect { node[3] }.to raise_error(IndexError) }
      it { expect { node[Node::Int] }.to raise_error(RuntimeError) }
      it { expect { node[Node::Float] }.to raise_error(RuntimeError) }
      it { node[Node::If].should equal node }
      it { node[Node::Send].should equal node[1] }
      it { node[:str].value.should == 'hello' }
    end

    describe :simple_literal? do
      # rubocop:disable Lint/PercentStringArray
      %w<nil true false 42 4.2 [] {} "hello" :world /foo/i>.each do |simple|
        it { Node[simple].should be_simple_literal }
      end
      %w<2*21 [42] {a:1} "hello#{42}" :"worl#{:d}" /foo#{42}/>.each do |not_so_simple| # rubocop:disable Lint/InterpolationCheck
        it { Node[not_so_simple].should_not be_simple_literal }
      end
      # rubocop:enable Lint/PercentStringArray
    end
  end
end
