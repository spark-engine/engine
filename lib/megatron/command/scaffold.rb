module Megatron
  class Scaffold
    attr_reader :name, :spec, :path, :gemspec_path

    def initialize(name)
      puts "Creating new plugin #{name}"
      @name = name.downcase
      @module_name = name.split('_').collect(&:capitalize).join
      @gemspec_path = create_gem
      @path = File.expand_path(File.dirname(name))
      @spec = Gem::Specification.load(@gemspec_path)

      bootstrap_gem
      engine_app_scaffold
      engine_site_scaffod
    end

    # Create a new gem with Bundle's gem command
    #
    def create_gem
      begin
        require 'bundler'
        require 'bundler/cli'
        Bundler::CLI.start(['gem', name])

        Dir.glob(File.join(name, "/*.gemspec")).first

      rescue LoadError
        raise "To use this feature you'll need to install the bundler gem with `gem install bundler`."
      end
    end

    def bootstrap_gem

      # Remove unnecessary bin dir
      FileUtils.rm_rf(File.join(path, 'bin'))

      # Simplify gempsec for these purposes
      File.open(gemspec_path, 'w') do |io|
        io.write gemspec
      end

      File.open "#{name}/lib/#{name}.rb", 'w' do |io|
        io.write %Q{require 'megatron'
require '#{name}/version'

module #{@module_name}
  class Plugin < Megatron::Plugin
  end
end

Megatron.register(#{@module_name}::Plugin, {
  name: '#{name}'
})}
      end
    end

    # Add engine's app assets and utilities
    def engine_app_scaffold

      # Add asset dirs
      %w(images javascripts stylesheets svgs).each do |path|
        FileUtils.mkdir_p("#{name}/app/assets/#{path}/#{name}")
      end

      # Add helper and layout dirs
      %w(helpers views/layouts).each do |path|
        FileUtils.mkdir_p("#{name}/app/#{path}/#{name}")
      end

      # Add an application helper
      File.open("#{name}/app/helpers/#{name}/application_helper.rb", 'w') do |io|
        io.write %Q{module #{@module_name}
  module ApplicationHelper
  end
end}
      end

      # Add an a base layout
      File.open("#{name}/app/views/layouts/#{name}/application.html.erb", 'w') do |io|
        io.write %Q{module #{@module_name}
  module ApplicationHelper
  end
end}
      end

    end

    def engine_site_scaffod

      FileUtils.mkdir_p(".#{name}-tmp")
      Dir.chdir ".#{name}-tmp" do
        response = Open3.capture3("rails plugin new #{name} --mountable --dummy-path=site --skip-test-unit")
        if !response[1].empty?
          exit "FAILED: Please be sure you have the rails gem installed with `gem install rails`"
        end

        %w(app config bin config.ru Rakefile public log).each do |item|
          FileUtils.cp_r(File.join(name, item), File.join(path, item))
        end

      end

      FileUtils.rm_rf(".#{name}-tmp")
    end

    def gemspec
%Q{# coding: utf-8
$:.push File.expand_path("../lib", __FILE__)

require "#{spec.name}/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "#{spec.name}"
  spec.version     = #{@module_name}::VERSION
  spec.authors     = #{spec.authors}
  spec.email       = #{spec.email}
  spec.summary     = "Summary of your gem."
  spec.description = "Description of your gem (usually longer)."
  spec.license     = "#{spec.license}"

  spec.files = Dir["{app,config,lib/public}/**/*", "LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", "~> #{`rails -v`.strip.split(' ').last}"
  spec.add_runtime_dependency "megatron"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
end
}
    end

    def create_empty_dirs(dirs)
      [dirs].flatten.each do |d|
        dir = File.join(d)
        action = Dir.exist?(dir) ? "exists".rjust(12) : "create".rjust(12)
        FileUtils.mkdir_p dir
        puts "#{action}  #{dir.sub("#{Dir.pwd}/", '')}/"
      end
    end
  end
end
