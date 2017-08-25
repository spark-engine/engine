require "open3"
require "json"
require "colorize"

require "cyborg/command"
require "cyborg/version"
require "cyborg/plugin"
require "cyborg/assets"
require "cyborg/sass/engine"
require "cyborg/sass/importer"
require "cyborg/config_data"

module Cyborg
  extend self
  attr_accessor :plugin
  autoload :Application, "cyborg/middleware"

  def production?
    ENV['CI'] || ENV['RAILS_ENV'] == 'production' || Command.production?
  end

  def rails5?
   Gem::Version.new(Rails.version) >= Gem::Version.new('5') 
  end

  def plugin
    @plugin
  end

  def config_data
    Cyborg::ConfigData.read(Cyborg.plugin.root, Rails.root)
  end

  def register(plugin_module, options={}, &block)
    @plugin = plugin_module.new(options)
    @plugin.create_engine(&block)
    patch_rails
  end

  def patch_rails
    load_helpers
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

  def rails_path(sub=nil)
    path = if at_rails_root
      Dir.pwd
    else
      dir = Dir["**/bin/rails"]
      if !dir.empty?
        dir.first.split('/').first
      end
    end
    path = File.join(path, sub) if sub
    path
  end
end
