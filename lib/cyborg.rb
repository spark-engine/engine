require "open3"
require "json"
require 'colorize'

require "cyborg/command"
require "cyborg/version"
require "cyborg/plugin"
require "cyborg/assets"

module Cyborg
  extend self
  attr_accessor :plugin
  autoload :Application, "cyborg/middleware"

  def production?
    ENV['CI'] || ENV['RAILS_ENV'] == 'production'
  end

  def plugin
    @plugin
  end

  def register(plugin_module, options={})
    @plugin = plugin_module.new(options)
    patch_rails
  end

  def patch_rails
    load_rake_tasks
    load_helpers
  end

  def dispatch(command, *args)
    @threads = []
    send(command, *args)
    @threads.each { |thr| thr.join }
  end

  def build(options={})
    puts 'Building…'
    require File.join(Dir.pwd, rails_path, 'config/application')
    @threads.concat plugin.build(options)
  end

  def watch(options={})
    build(options)
    require 'listen'

    trap("SIGINT") { 
      puts "\nCyborg watcher stopped. Have a nice day!"
      exit! 
    }

    @threads.concat plugin.watch(options)
  end

  def server(options={})
    @threads << Thread.new { Cyborg::Command.from_rails 'rails server' }
    watch(options)
  end

  def load_rake_tasks
    plugin.engine.rake_tasks do
      namespace :cyborg do
        desc "Cyborg build task"
        task :build do
          Cyborg.dispatch(:build)
        end

        desc "Watch assets for build"
        task :watch do
          Cyborg.dispatch(:watch)
        end

        desc "Start rails and watch assets for build"
        task :server do
          Cyborg.dispatch(:server)
        end
      end
    end
  end

  def load_helpers
    require "cyborg/helpers/asset_helpers"
    require "cyborg/helpers/layout_helpers"

    Cyborg::Helpers.constants.each do |c|
      helper = Cyborg::Helpers.const_get(c)
      ActionView::Base.send :include, helper if defined? ActionView::Base
    end
  end

  def at_rails_root
    File.exist?("bin/rails")
  end

  def at_gem_root
    !Dir['*.gemspec'].empty?
  end

  def gem_path
    if at_gem_root
      Dir.pwd
    elsif at_rails_root
      "../"
    end
  end

  def rails_path
    if at_rails_root
      Dir.pwd
    else
      dir = Dir["**/bin/rails"]
      if !dir.empty?
        dir.first.split('/').first
      end
    end
  end
end
