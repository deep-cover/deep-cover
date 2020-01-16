# frozen_string_literal: true
require 'bundler/setup'
require 'deep_cover'

# Check also .deep_cover.rb file
DeepCover.configure do
  ignore_uncovered :default_argument
  paths '.'
end

DeepCover.cover do
  require_relative 'foo'
end

Foo.new.bar(1)
Foo.new.bar(2)

p DeepCover.line_coverage('foo')
