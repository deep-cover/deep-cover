# frozen_string_literal: true

require 'spec_helper'

module DeepCover
  RSpec.describe Memoize do
    class Test
      include Memoize
      memoize :foo
      def initialize
        @val = 0
      end

      def foo
        @val += 1
      end
    end

    class TestFrozen < Test
      memoize :foo
      def initialize
        super
        freeze
      end
    end

    class TestInheritance < Test
      memoize :foo, :qux
      def foo
        100 + super
      end

      def baz
        @baz ||= 0
        @baz += 1
      end

      def qux
        [42]
      end
    end

    let(:o) { klass.new }
    let(:subject) { o }
    describe 'Hot class' do
      let(:klass) { Test }
      it { klass.memoized.should =~ [:foo] }
      it 'maintains arity 0' do
        klass.instance_method(:foo).arity.should == 0
      end
      it 'is memoized' do
        o.foo.should == 1
        o.foo.should == 1
      end
    end

    describe 'Inheritance' do
      let(:klass) { TestInheritance }
      it { klass.memoized.should =~ [:foo, :qux] }
      it 'is memoized' do
        o.foo.should == 101
      end
      it 'freezes memoized results' do
        o.qux.should be_frozen
      end
    end

    describe 'Frozen class' do
      let(:klass) { TestFrozen }
      it { klass.memoized.should =~ [:foo] }
      it 'is memoized' do
        o.foo.should == 1
        o.foo.should == 1
      end
    end
  end
end
