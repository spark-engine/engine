# coding: utf-8
$:.push File.expand_path("../lib", __FILE__)
require 'cyborg/version'

Gem::Specification.new do |spec|
  spec.name          = "cyborg"
  spec.version       = Cyborg::VERSION
  spec.authors       = ["Brandon Mathis"]
  spec.email         = ["brandon@imathis.com"]

  spec.summary       = %q{Build style-guide plugins Rails (and humans).}
  spec.description   = %q{Build style-guide plugins Rails (and humans).}
  spec.homepage      = "https://github.com/compose-ui/cyborg"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "sass"
  spec.add_runtime_dependency "esvg", "~> 2.9.1"
  spec.add_runtime_dependency "listen", "~> 3.0"
  spec.add_runtime_dependency 'block_helpers', '~> 0.3.3'
  spec.add_runtime_dependency 'colorize'
  spec.add_runtime_dependency "bundler", "~> 1.11"

  spec.add_runtime_dependency "rails", "~> 4"
  spec.add_dependency 'rack-cors'

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
end
