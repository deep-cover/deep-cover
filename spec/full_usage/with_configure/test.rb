require 'bundler/setup'
require 'deep_cover'

DeepCover.configure do
  detect_uncovered :default_argument
  ignore_uncovered :raise
end

DeepCover.cover do
  require_relative 'foo'
end

Foo.new.bar(1)
Foo.new.bar(2)

p DeepCover.line_coverage('foo')
