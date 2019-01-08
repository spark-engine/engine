# coding: utf-8
$:.push File.expand_path('../lib', __FILE__)
require 'spark_engine/version'

Gem::Specification.new do |spec|
  spec.name          = 'spark_engine'
  spec.version       = SparkEngine::VERSION
  spec.authors       = ['Brandon Mathis']
  spec.email         = ['brandon@imathis.com']

  spec.summary       = %q{A design system framework for Rails (and humans).}
  spec.homepage      = 'https://github.com/imathis/spark'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'sass', '~> 3.4'
  spec.add_runtime_dependency 'esvg', '~> 4.2'
  spec.add_runtime_dependency 'block_helpers', '~> 0.3'
  spec.add_runtime_dependency 'colorize', '~> 0.8'
  spec.add_runtime_dependency 'bundler', '~> 1.10'
  spec.add_runtime_dependency 'autoprefixer-rails', '>= 8.0', '< 10'

  spec.add_development_dependency 'rails', '>= 5.0', '< 6'
  spec.add_development_dependency 'listen', '~> 3.0.0'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'pry-byebug'
end
