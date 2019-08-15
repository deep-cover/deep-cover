# frozen_string_literal: true
require 'bundler/setup'
require 'deep_cover'

# Check also .deep_cover.rb file
DeepCover.configure do
  ignore_uncovered :default_argument
  paths '.'
  exclude_paths 'bar'
end

DeepCover.cover do
  require_relative 'foo'
end

require_relative 'run'

out = %w[foo bar].to_h do |f|
  [f.to_sym, DeepCover.line_coverage(f)]
end
p out
