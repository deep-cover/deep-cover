# frozen_string_literal: true

require_relative 'core_gem/lib/deep_cover/version'

Gem::Specification.new do |spec|
  spec.name          = 'deep-cover'
  spec.version       = DeepCover::VERSION
  spec.authors       = ['Marc-André Lafortune', 'Maxime Lapointe']
  spec.email         = ['github@marc-andre.ca', 'hunter_spawn@hotmail.com']

  spec.summary       = 'In depth coverage of your Ruby code.'
  spec.description   = 'expression and branch coverage for Ruby.'
  spec.homepage      = 'https://github.com/deep-cover/deep-cover'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|\w+_gem)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  ### Runtime dependencies
  spec.required_ruby_version = '>= 2.1.0'

  # Main dependency
  spec.add_runtime_dependency 'deep-cover-core', DeepCover::VERSION

  # CLI
  spec.add_runtime_dependency 'bundler'
  spec.add_runtime_dependency 'highline'
  spec.add_runtime_dependency 'slop', '~> 4.0'
  spec.add_runtime_dependency 'term-ansicolor'
  spec.add_runtime_dependency 'with_progress'

  ### Dev dependencies
  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'psych', '>= 2.0'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '0.53.0' # About every single release breaks something
  spec.add_development_dependency 'sass'
end
