require 'fileutils'

module Cyborg
  class Scaffold
    attr_reader :gem, :engine, :namespace, :plugin_module, :spec, :path, :gemspec_path

    def initialize(options)
      @cwd = Dir.pwd
      @gem = underscorize(options[:name])
      @engine = underscorize(options[:engine] || options[:name])
      @namespace = @engine
      @plugin_module = modulize @engine

      puts "Creating new plugin #{@namespace}".bold
      engine_site_scaffold

      @gemspec_path = new_gem
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
    def new_gem
      system "bundler gem #{gem}"
      Dir.glob(File.join(gem, "/*.gemspec")).first
    end

    def install_npm_modules
      Dir.chdir path do
        NPM.setup
      end
    end

    # First remove scaffold spec.files (which rely on git) to avoid errors
    # when loading the spec
    def fix_gemspec_files
      write_file(gemspec_path, File.read(gemspec_path).gsub(/^.+spec\.files.+$/,''))
    end

    def bootstrap_gem

      # Remove unnecessary bin dir
      FileUtils.rm_rf(File.join(path, 'bin'))

      # Simplify gempsec and set up to add assets properly
      write_file(gemspec_path, gemspec)

      write_file("#{gem}/lib/#{gem}.rb", %Q{require 'cyborg'
require '#{gem}/version'

module #{modulize(gem)}
  class Plugin < Cyborg::Plugin
  end
end

Cyborg.register(#{modulize(gem)}::Plugin, {
  #{cyborg_plugin_config}
})})
    end

    def cyborg_plugin_config
      plugin_config = "gem: '#{gem}'"
      plugin_config += ",\n  engine: '#{engine}'" if engine
      plugin_config
    end

    # Add engine's app assets and utilities
    def engine_app_scaffold

      # Add asset dirs
      files = %w(images javascripts stylesheets svgs).map { |path|
        "#{gem}/app/assets/#{path}/#{namespace}/.keep"
      }

      write_file(files, '')

      # Add helper and layout dirs
      files = %w(helpers views/layouts).each { |path|
        "#{gem}/app/#{path}/#{namespace}"
      }

      write_file(files, '')

      # Add an application helper
      write_file("#{gem}/app/helpers/#{namespace}/application_helper.rb", %Q{module #{plugin_module}
  module ApplicationHelper
  end
end})

      # Add an a base layout
      write_file("#{gem}/app/views/layouts/#{namespace}/default.html.erb", %Q{<!DOCTYPE html>
<html>
<head>
  <title>#{plugin_module}</title>
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
</html>})


      # Update .gitignore
      write_file("#{gem}/.gitignore", %Q{.DS_Store
log/*.log
pkg/
node_modules
site/log/*.log
site/tmp/
/public/
_svg.js
.sass-cache}, 'a')
    end

    def engine_site_scaffold
      FileUtils.mkdir_p(".#{gem}-tmp")
      Dir.chdir ".#{gem}-tmp" do
        response = Open3.capture3("rails plugin new #{gem} --mountable --dummy-path=site --skip-test-unit")
        if !response[1].empty?
          puts response[1]
          abort "FAILED: Please be sure you have the rails gem installed with `gem install rails`"
        end
      end
    end

    def engine_copy
      site_path = File.join(path, 'site')
      FileUtils.mkdir_p(site_path)

      Dir.chdir ".#{gem}-tmp/#{gem}" do
        %w(app config bin config.ru Rakefile public log).each do |item|
          target = File.join(site_path, item)

          FileUtils.cp_r(File.join('site', item), target)
          action_log "create", target.sub(@cwd+'/','')
        end

      end

      FileUtils.rm_rf(".#{gem}-tmp")
      %w(app/mailers app/models config/database.yml).each do |item|
        FileUtils.rm_rf(File.join(site_path, item))
      end
    end

    def prepare_engine_site
      site_path = File.join(path, 'site')

      write_file(File.join(site_path, 'config/environments/development.rb'), %Q{Rails.application.configure do
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log
end
})

      write_file(File.join(site_path, 'config/application.rb'), %Q{require File.expand_path('../boot', __FILE__)

require "rails"
# Pick the frameworks you want:
require "action_controller/railtie"
require "action_view/railtie"
require "sprockets/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

require '#{gem}'

module Site
  class Application < Cyborg::Application
  end
end})

      write_file(File.join(site_path, 'config/routes.rb'), %Q{Rails.application.routes.draw do
  resources :docs, param: :page, path: ''
end})

      write_file(File.join(site_path, 'app/controllers/docs_controller.rb'), %Q{class DocsController < ApplicationController
  def show
    render action: "#\{params[:page]\}"
  end
end})

      write_file(File.join(site_path, 'app/views/layouts/default.html.erb'), "<%= render_layout do %>\n<% end %>")

      write_file(File.join(site_path, 'app/views/docs/index.html.erb'), "<h1>#{plugin_module} Documentation</h1>")
    end

    def update_git
      Dir.chdir gem do
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
  spec.version     = #{modulize(gem)}::VERSION
  spec.authors     = #{spec.authors}
  spec.email       = #{spec.email}
  spec.summary     = "Summary of your gem."
  spec.description = "Description of your gem (usually longer)."
  spec.license     = "#{spec.license}"

  spec.files = Dir["{app,lib,public}/**/*", "LICENSE.txt", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 4"
  spec.add_runtime_dependency "cyborg"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
end
}
    end

    def write_file(paths, content, mode='w')
      paths = [paths].flatten
      paths.each do |path|
        if File.exist?(path)
          type = 'update'
        else
          FileUtils.mkdir_p(File.dirname(path))
          type = 'create'
        end

        File.open path, mode do |io|
          io.write(content)
        end

        action_log(type, path)
      end
    end

    def action_log(action, path)
      puts action.rjust(12).colorize(:green).bold + "  #{path}"
    end

    def modulize(input)
      input.split('_').collect(&:capitalize).join
    end

    def underscorize(input)
      input.gsub(/[A-Z]/) do |char|
        '_'+char
      end.sub(/^_/,'').downcase
    end
  end
end
