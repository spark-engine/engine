module Megatron
  class Scaffold
    attr_reader :name, :spec, :path, :gemspec_path

    def initialize(name)
      @name = name.downcase
      @module_name = name.split('_').collect(&:capitalize).join

      puts "Creating new plugin #{name}"
      engine_site_scaffod

      @gemspec_path = create_gem
      @path = File.expand_path(File.dirname(@gemspec_path))
      @spec = Gem::Specification.load(@gemspec_path)

      bootstrap_gem
      engine_app_scaffold
      engine_copy
      prepare_engine_site
      #reset_git
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
        io.write %Q{<!DOCTYPE html>
<html>
<head>
  <title>#{@module_name}</title>
  <%= csrf_meta_tags %>
  <%= asset_tags %>
  <%= yield :stylesheets %>
  <%= yield :javascripts %>
  <%= yield :head %>
</head>
<body>

<div class='site'>
  <div class='page'><%=yield %></div>
</div>
</body>
</html>}
      end

      File.open("#{name}/.gitignore", 'a') do |io|
        io.write %Q{.DS_Store
log/*.log
pkg/
node_modules
site/log/*.log
site/tmp/
.sass-cache}
      end

    end

    def engine_site_scaffod
      FileUtils.mkdir_p(".#{name}-tmp")
      Dir.chdir ".#{name}-tmp" do
        response = Open3.capture3("rails plugin new #{name} --mountable --dummy-path=site --skip-test-unit")
        if !response[1].empty?
          puts response[1]
          abort "FAILED: Please be sure you have the rails gem installed with `gem install rails`"
        end
      end
    end

    def engine_copy
      site_path = File.join(path, 'site')
      FileUtils.mkdir_p(site_path)

      Dir.chdir ".#{name}-tmp/#{name}" do
        %w(app config bin config.ru Rakefile public log).each do |item|
          target = File.join(site_path, item)

          FileUtils.cp_r(File.join('site', item), target)
        end

      end

      FileUtils.rm_rf(".#{name}-tmp")
      %w(app/mailers app/models config/database.yml).each do |item|
        FileUtils.rm_rf(File.join(site_path, item))
      end
    end

    def prepare_engine_site
      site_path = File.join(path, 'site')

      File.open File.join(site_path, 'config/environments/development.rb'), 'w' do |io|
        io.write %Q{Rails.application.configure do
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log
end
        }
      end

      File.open File.join(site_path, 'config/application.rb'), 'w' do |io|
        io.write %Q{require File.expand_path('../boot', __FILE__)

require "rails"
# Pick the frameworks you want:
require "action_controller/railtie"
require "action_view/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Site
  class Application < Megatron::Application
  end
end}
      end

      File.open File.join(site_path, 'config/routes.rb'), 'w' do |io|
        io.write %Q{Rails.application.routes.draw do
  resources :docs, param: :page, path: ''
end}
      end

      File.open File.join(site_path, 'app/controllers/docs_controller.rb'), 'w' do |io|
        io.write %Q{class DocsController < ApplicationController
  def show
    render action: "#\{params[:page]\}"
  end
end}
      end

      File.open File.join(site_path, 'app/views/layouts/application.html.erb'), 'w' do |io|
        io.write %Q{<%= layout '#{name}' do %>\n<% end %>}
      end
      FileUtils.mkdir_p File.join(site_path, 'app/views/docs')
      File.open File.join(site_path, 'app/views/docs/index.html.erb'), 'w' do |io|
        io.write %Q{<h1>#{@module_name} Documentaiton</h1>}
      end
    end

    def reset_git
      system "git reset"
      system "git add -A"
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
