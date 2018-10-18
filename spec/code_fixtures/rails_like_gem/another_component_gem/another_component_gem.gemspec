# coding: utf-8
version = File.read(File.expand_path("../RAILS_LIKE_VERSION", __dir__)).strip

Gem::Specification.new do |spec|
  spec.name          = "another_component_gem"
  spec.version       = version
  spec.authors       = ["Marc-Andre Lafortune"]
  spec.email         = ["github@marc-andre.ca"]

  spec.summary       = %q{Rails like repo}
  spec.description   = %q{Rails like repo}
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
  if ENV["DEEP_COVER"]
    # Not in clone mode
    spec.add_development_dependency "deep-cover-core"
  end
end
