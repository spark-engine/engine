# coding: utf-8
$:.push File.expand_path("../lib", __FILE__)

require "<%= @spec.name %>/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "<%= @spec.name %>"
  spec.version     = <%= @gem_module %>::VERSION
  spec.authors     = <%= @spec.authors %>
  spec.email       = <%= @spec.email %>
  spec.summary     = "Summary of your gem."
  spec.description = "Description of your gem (usually longer)."
  spec.license     = "<%= @spec.license %>"

  spec.files         = Dir["{app,lib,public,config}/**/*", "LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 4"
  spec.add_runtime_dependency "spark_engine"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
end
