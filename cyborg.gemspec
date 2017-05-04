# coding: utf-8
$:.push File.expand_path('../lib', __FILE__)
require 'cyborg/version'

Gem::Specification.new do |spec|
  spec.name          = 'cyborg'
  spec.version       = Cyborg::VERSION
  spec.authors       = ['Brandon Mathis']
  spec.email         = ['brandon@imathis.com']

  spec.summary       = %q{Build a great style-guide for Rails (and humans).}
  spec.description   = %q{This is a tool for creating powerufl style guides using rails engines and awesomeness.}
  spec.homepage      = 'https://github.com/compose-ui/cyborg'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'sass', '~> 3.4'
  spec.add_runtime_dependency 'esvg', '~> 3.2'
  spec.add_runtime_dependency 'listen', '~> 3.0.0'
  spec.add_runtime_dependency 'block_helpers', '~> 0.3'
  spec.add_runtime_dependency 'colorize', '~> 0.8'
  spec.add_runtime_dependency 'bundler', '~> 1.10'
  spec.add_runtime_dependency 'autoprefixer-rails', '~> 6.4'
  spec.add_runtime_dependency 'rack-cors', '~> 0.4'
  spec.add_runtime_dependency 'rails', '>= 4.2', '< 6'

  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'pry-byebug'
end
