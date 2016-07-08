# coding: utf-8
$:.push File.expand_path("../lib", __FILE__)
require 'megatron/version'

Gem::Specification.new do |spec|
  spec.name          = "megatron"
  spec.version       = Megatron::VERSION
  spec.authors       = ["Brandon Mathis", "Jérôme Gravel-Niquet"]
  spec.email         = ["brandon@imathis.com", "jeromegn@gmail.com"]

  spec.summary       = %q{A Style-guide system for Rails and humans.}
  spec.description   = %q{A Style-guide system for Rails and humans.}
  #spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "sass"
  spec.add_runtime_dependency "esvg", "~> 2.8.10"
  spec.add_runtime_dependency "listen", "~> 3.0"
  spec.add_runtime_dependency 'block_helpers', '~> 0.3.3'
  spec.add_runtime_dependency 'colorize'

  spec.add_runtime_dependency "rails", "~> 4"
  spec.add_dependency 'rack-cors'

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
end
