# frozen_string_literal: true

require_relative 'lib/deep_cover/version'

Gem::Specification.new do |spec|
  spec.name          = 'deep-cover-core'
  spec.version       = DeepCover::VERSION
  spec.authors       = ['Marc-André Lafortune', 'Maxime Lapointe']
  spec.email         = ['github@marc-andre.ca', 'hunter_spawn@hotmail.com']

  spec.summary       = 'In depth coverage of your Ruby code.'
  spec.description   = 'Core functionality for the DeepCover gem.'
  spec.homepage      = 'https://github.com/deep-cover/deep-cover'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  ### Runtime dependencies
  spec.required_ruby_version = '>= 2.1.0'

  # Main dependency
  spec.add_runtime_dependency 'parser', '~> 2.5.0'

  # Support
  spec.add_runtime_dependency 'backports', '>= 3.11.0'
  spec.add_runtime_dependency 'binding_of_caller'

  # Reporters
  spec.add_runtime_dependency 'terminal-table'

  # While in 0.x
  spec.add_runtime_dependency 'pry'

  ### Dev dependencies
  spec.add_development_dependency 'bundler', '~> 1.15'
  spec.add_development_dependency 'psych', '>= 2.0'
  spec.add_development_dependency 'rake', '~> 12.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '0.53.0' # About every single release breaks something
end
