require 'spark_engine/sass/importer'

# Taken from https://github.com/chriseppstein/sass-css-importer/blob/master/lib/sass/css_importer/monkey_patches.rb
# TODO: This feels wrong, surely there must be a better way to handle this

class Sass::Engine
  alias initialize_without_yaml_importer initialize

  def initialize(template, options={})
    initialize_without_yaml_importer(template, options)

    yaml_importer = self.options[:load_paths].find {|lp| lp.is_a?(SparkEngine::Importer) }

    unless yaml_importer
      root        = File.dirname(options[:filename] || ".")
      plugin_root = SparkEngine.plugin.stylesheets.base
      self.options[:load_paths] << SparkEngine::Importer.new(root)
      self.options[:load_paths] << SparkEngine::Importer.new(plugin_root)
    end
  end
end
