# frozen_string_literal: true

require_relative 'spec_helper'
require 'deep_cover/tools'

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

    describe :content_tag do
      it 'works' do
        Tools.content_tag(:div, 'hello').should == '<div>hello</div>'
      end
      it 'works with a block' do
        Tools.content_tag(:span, 'hello', class: 'foo', id: 'bar').should ==
          %{<span class="foo" id="bar">hello</span>}
      end
    end
  end
end
