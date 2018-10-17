# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in deep_cover.gemspec
gemspec

eval_gemfile File.expand_path('Gemfile.local', __dir__) if File.exist?('Gemfile.local')

# This is a workaround for rubymine to stop treating the core_gem directory like an external library...
# https://youtrack.jetbrains.com/issue/RUBY-18315#comment=27-1608735
gem_name = 'deep-cover-core'
gem_path = 'core_gem'
gem gem_name, path: gem_path

gem 'ruby-prof', platforms: :mri
