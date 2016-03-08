require "positron/version"

module Positron
  extend self

  OPTIONS = {
    config_file:  './positron.yml',
    js_path:      './app/assets/positron/javascripts/index.js',
    css_path:     './app/assets/positron/stylesheets/index.scss',
    output_path:  './public/assets/',
    npm_path:     './node_modules'
  }

  def run(options)
    options = options.merge
    read_config(options[:config_file])
    if options[:command] == 'build'
      build(options)
    end
  end

  def read_config(file)
    @config = if file && File.exist?(file)
      Yaml.load(File.read(file))
    else
      {}
    end
  end

  def build(options)
    build_svg(options) if options[:svg]
    build_js(options)  if options[:js]
    build_css(options) if options[:css]
  end

  def build_js(options)
    output_path = options[:js_output_path].sub(/\.js$/, "-#{options[:version]}")
    browserfy_path = File.join(options[:npm_path], ".bin/browserify")
    command = "#{browserfy_path} #{options[:js_path]} -t "
    + "babelify --standalone #{options[:js_module_name]} -o #{output_path}.js " 
    + "-d -p [ minifyify --map #{File.basename(output_path)}.map.json --output #{output_path}.map.json ]"

    system command
  end
end
