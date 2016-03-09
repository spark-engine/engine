require "positron/version"

module Positron
  extend self

  OPTIONS = {
    config_file:  './positron.yml',
    js_path:      './positron/javascripts/index.js',
    css_path:     './positron/stylesheets/index.scss',
    svg_dir:      './positron/svgs/',
    output_path:  './positron/build/',
    npm_path:     './node_modules'
  }

  def run(options)
    options = options.merge
    read_config(options[:config_file])

    if options[:command] == 'build'
      build(options)
    end

    # Add dependencies somehow
    #
    # "babelify": "^6.1.3",
    # "browserify": "^11.0.1",
    # "minifyify": "^7.0.3",
    # "watchify": "^3.3.1"
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

  def watch(options)
    processes = []
    processes.push 'svg=1' if options[:svg]
    processes.push 'js=1' if options[:js]
    processes.push 'css=1' if options[:css]

    procfile_path = File.join(File.expand_path(File.dirname(__FILE__)), 'positron/procfile')

    system "foreman start -c #{processes.join} -f #{procfile_path}"
  end

  def build_js(options)
    output_path = options[:js_output_path].sub(/\.js$/, "-#{options[:version]}")
    browserfy_path = File.join(options[:npm_path], ".bin/browserify")

    command = "#{browserfy_path} #{options[:js_path]} -t "
    + "babelify --standalone #{options[:js_module_name]} -o #{output_path}.js " 
    + "-d -p [ minifyify --map #{File.basename(output_path)}.map.json --output #{output_path}.map.json ]"

    system command
  end

  def build_svg(options)
    require 'esvg'

    if @svg.nil? 
      @svg = Esvg::SVG.new(config_file: options[:config_file], cli: true, optimize: true)
    else
      @svg.read_files
    end

    @svg.write
  end

  def watch_js(options)
    output_path = options[:js_output_path].sub(/\.js$/, "-#{options[:version]}")
    watchify_path = File.join(options[:npm_path], ".bin/watchify")

    command = "#{browserfy_path} #{options[:js_path]} --poll --debug -t "
    + "babelify #{options[:js_module_name]} -o #{output_path}.js -v" 

    system command
  end

  def watch_css(options)
    require 'listen'

    listener = Listen.to(options[:css_path], only: /\.scss$/) do |modified, added, removed|
      build_css(options)
    end

    build_css

    puts "Initial CSS build, done. Listening for changes..."

    listener.start # not blocking
    sleep
  end

  def watch_svg(options)
    require 'listen'

    listener = Listen.to(options[:svg_dir], only: /\.svg$/) do |modified, added, removed|
      build_svg
    end

    build_svg

    puts "Initial SVG build, done. Listening for changes..."

    listener.start # not blocking
    sleep
  end
  
  def gzip(glob)
    Dir["#{Dir.pwd}/#{glob}"].each do |f|
      next unless f =~ ZIP_TYPES

      mtime = File.mtime(f)
      gz_file = "#{f}.gz"
      next if File.exist?(gz_file) && File.mtime(gz_file) >= mtime

      File.open(gz_file, "wb") do |dest|
        gz = Zlib::GzipWriter.new(dest, Zlib::BEST_COMPRESSION)
        gz.mtime = mtime.to_i
        IO.copy_stream(open(f), gz)
        gz.close
      end

      File.utime(mtime, mtime, gz_file)
    end
  end
end
