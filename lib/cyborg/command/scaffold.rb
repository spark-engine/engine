require 'fileutils'

module Cyborg
  class Scaffold
    attr_reader :name, :spec, :path, :gemspec_path

    def initialize(name)
      @cwd = Dir.pwd
      @name = name.downcase
      @module_name = name.split('_').collect(&:capitalize).join

      puts "Creating new plugin #{name}".bold
      engine_site_scaffold

      @gemspec_path = create_gem
      @path = File.expand_path(File.dirname(@gemspec_path))

      fix_gemspec_files

      @spec = Gem::Specification.load(@gemspec_path)

      bootstrap_gem
      engine_app_scaffold
      engine_copy
      prepare_engine_site
      install_npm_modules
      update_git
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

    def install_npm_modules
      Dir.chdir path do
        NPM.setup
      end
    end

    # First remove scaffold spec.files (which rely on git) to avoid errors
    # when loading the spec
    def fix_gemspec_files
      gs = File.read(gemspec_path)

      File.open(gemspec_path, 'w') do |io|
        io.write gs.gsub(/^.+spec\.files.+$/,'')
      end
    end

    def bootstrap_gem

      # Remove unnecessary bin dir
      FileUtils.rm_rf(File.join(path, 'bin'))

      # Simplify gempsec and set up to add assets properly
      File.open(gemspec_path, 'w') do |io|
        io.write gemspec
      end

      action_log "update", gemspec_path

      File.open "#{name}/lib/#{name}.rb", 'w' do |io|
        io.write %Q{require 'megatron'
require '#{name}/version'

module #{@module_name}
  class Plugin < Cyborg::Plugin
  end
end

Cyborg.register(#{@module_name}::Plugin, {
  name: '#{name}'
})}
      end
      action_log "update", "#{name}/lib/#{name}.rb"
    end

    # Add engine's app assets and utilities
    def engine_app_scaffold

      # Add asset dirs
      %w(images javascripts stylesheets svgs).each do |path|
        path = "#{name}/app/assets/#{path}/#{name}"
        FileUtils.mkdir_p path
        FileUtils.touch File.join(path, '.keep')
        action_log "create", path
      end

      # Add helper and layout dirs
      %w(helpers views/layouts).each do |path|
        path = "#{name}/app/#{path}/#{name}"
        FileUtils.mkdir_p path
        action_log "create", path
      end

      # Add an application helper
      File.open("#{name}/app/helpers/#{name}/application_helper.rb", 'w') do |io|
        io.write %Q{module #{@module_name}
  module ApplicationHelper
  end
end}
        action_log "create", "#{name}/app/helpers/#{name}/application_helper.rb"
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
      action_log "create", "#{name}/app/views/layouts/#{name}/application.html.erb"

      File.open("#{name}/.gitignore", 'a') do |io|
        io.write %Q{.DS_Store
log/*.log
pkg/
node_modules
site/log/*.log
site/tmp/
/public/
browserify-cache.json
_svg.js
.sass-cache}
      end
      action_log "update", "#{name}/.gitignore"
    end

    def engine_site_scaffold
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
          action_log "create", target.sub(@cwd+'/','')
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
require 'bundler'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require '#{name}'
require 'sprockets/railtie'

module Site
  class Application < Cyborg::Application
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

    def update_git
      Dir.chdir @name do
        system "git reset"
        system "git add -A"
      end
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

    def action_log(action, path)
      puts action.rjust(12).colorize(:green).bold + "  #{path}"
    end
  end
end
