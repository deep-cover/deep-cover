# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "covered_trivial_gem/version"

Gem::Specification.new do |spec|
  spec.name          = "covered_trivial_gem"
  spec.version       = CoveredTrivialGem::VERSION
  spec.authors       = ["Marc-Andre Lafortune"]
  spec.email         = ["github@marc-andre.ca"]

  spec.summary       = %q{Trivial spec fixture}
  spec.description   = %q{Trivial spec fixture}
  spec.homepage      = "http://example.org"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z 2> /dev/null`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "deep-cover"
end
