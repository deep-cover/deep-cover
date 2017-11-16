# frozen_string_literal: true

require 'spec_helper'

module DeepCover
  RSpec.describe Tools do
    describe :merge do
      it 'works with no block' do
        Tools.merge({a: 1}, {}, {a: 2, b: 2}, b: 3).should == {a: 2, b: 3}
      end
      it 'works with a block' do
        Tools.merge({a: 1}, {}, {a: 2, b: 2}, b: 3) { |a, b| a * b }.should == {a: 2, b: 6}
      end
      it 'works with a symbol' do
        Tools.merge({a: 1}, {}, {a: 2, b: 2}, {b: 3}, :+).should == {a: 3, b: 5}
      end
    end
  end
end
