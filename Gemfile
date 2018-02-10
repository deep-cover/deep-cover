# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

# Specify your gem's dependencies in deep_cover.gemspec
gemspec

eval_gemfile 'Gemfile.local' if File.exist?('Gemfile.local')

gem 'ruby-prof', platforms: :mri
