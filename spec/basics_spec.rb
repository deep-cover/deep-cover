# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'DeepCover::OPTIONALLY_COVERED' do
  it 'is set properly' do
    list = DeepCover::Node::Mixin::Filters.instance_methods(false).map do |method|
      method =~ /^is_(.*)\?$/
      Regexp.last_match(1)
    end.compact.sort.map(&:to_sym)

    DeepCover::OPTIONALLY_COVERED.should =~ list
  end
end
