require "open3"
require "json"
require "colorize"

require "spark_engine/version"
require "spark_engine/plugin"
require "spark_engine/assets"
require "spark_engine/data"

# Allow for either either SassC or Sass
begin
  require "spark_engine/sassc/extension"
rescue LoadError => e
  require "spark_engine/sass/engine"
end


module SparkEngine
  autoload :BlockHelper,     'spark_engine/helpers/block_helper'

  extend self
  attr_accessor :plugin

  def production?
    ENV['CI'] || ENV['RAILS_ENV'] == 'production' || ( defined?(Command) && Command.production? )
  end

  def plugin
    @plugin
  end

  def data
    if production?
      @data ||= SparkEngine::Data.read
    else
      SparkEngine::Data.read
    end
  end

  def register(plugin_module, options={}, &block)
    @plugin = plugin_module.new(options)
    if defined? Rails
      @plugin.create_engine(&block)
      patch_rails
    end
  end

  def patch_rails
    load_helpers
  end

  def load_helpers
    require "spark_engine/helpers/asset_helpers"
    require "spark_engine/helpers/layout_helpers"

    SparkEngine::Helpers.constants.each do |c|
      helper = SparkEngine::Helpers.const_get(c)
      ActionView::Base.send :include, helper if defined? ActionView::Base
    end
  end

  def at_rails_root?
    File.exist?("bin/rails")
  end

  def plugin_gemspec
    if gem_path
      path = File.join(gem_path, "*.gemspec")
      Dir[path].first
    end
  end

  def plugin_spec
    @plugin_spec ||= begin
      if file = plugin_gemspec
        spec = Gem::Specification.load(file)
        spec if spec.name != 'spark_engine'
      end
    end
  end

  def load_plugin
    plugin || if spec = plugin_spec
      require spec.name unless spec.name == 'spark_engine'
      return plugin
    end
  end

  def at_gem_root?
    !Dir['*.gemspec'].empty?
  end

  def gem_path
    if at_gem_root?
      Dir.pwd
    elsif at_rails_root?
      "../"
    end
  end

  def rails_path(sub=nil)
    path = if at_rails_root?
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
