#Gem.loaded_specs['megatron'].dependencies.each do |d|
  #require d.name
#end

require "megatron/version"
require "megatron/command"
require "megatron/plugin"
require "megatron/assets"
#require "megatron/watch"

module Megatron
  extend self
  autoload :Application, "megatron/middleware"

  def production?
    ENV['CI'] || ENV['RAILS_ENV'] == 'production'
  end

  def plugins
    @plugins ||= []
  end

  def register(plugin_module, options={})
    plugins << plugin_module.const_set('Plugin', Class.new(Megatron::Plugin)).new(options)
    patch_rails
  end

  def patch_rails
    load_rake_tasks
    load_helpers
  end

  def dispatch(command)
    @threads = []
    send(command)
  end

  def build
    puts 'Building…'

    Megatron.plugins.each do |plugin|
      @threads.concat plugin.build
    end

    @threads.each { |thr| thr.join }
  end

  def watch
    build
    require 'listen'

    trap("SIGINT") { 
      puts "\nMegatron watcher stopped. Have a nice day!"
      exit! 
    }

    Megatron.plugins.each do |plugin|
      @threads.concat plugin.watch
    end

    @threads.compact.each { |thr| thr.join }
  end

  def server
    watch
    @threads << Thread.new { system 'rails s' }
  end

  def load_rake_tasks
    return if @tasks_loaded
    plugins.first.engine.rake_tasks do
      namespace :megatron do
        desc "Megatron build task"
        task :build do
          Megatron.dispatch(:build)
        end

        desc "Watch assets for build"
        task :watch do
          Megatron.dispatch(:watch)
        end

        desc "Start rails and watch assets for build"
        task :server do
          Megatron.dispatch(:server)
        end
      end
    end

    @tasks_loaded = true
  end

  def load_helpers
    require "megatron/helpers/asset_helpers"
    require "megatron/helpers/layout_helpers"

    Megatron::Helpers.constants.each do |c|
      helper = Megatron::Helpers.const_get(c)
      ActionView::Base.send :include, helper if defined? ActionView::Base
    end
  end

end
