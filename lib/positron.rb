require "positron/version"
require "yaml"
require 'pp'

module Positron
  extend self

  DEFAULTS = {
    app_name:     'application',
    config_file:  './positron.yml',
    js_dir:      './app/assets/positron/javascripts/',
    css_dir:     './app/assets/positron/stylesheets/',
    svg_dir:     './app/assets/positron/svgs/',
    output_dir:  './public/assets/positron/',
    npm_dir:     './node_modules'
  }

  def run(options)
    config(options)

    build if config[:command] == 'build'
    watch if config[:command] == 'watch'

    # Add dependencies somehow
    #
    # "babelify": "^6.1.3",
    # "browserify": "^11.0.1",
    # "minifyify": "^7.0.3",
    # "watchify": "^3.3.1"
  end

  def config(cli_options={})
    @config ||= begin
      file_config = read_config(cli_options[:config_file])

      # Merge with oder: Defaults < File Config < CLI options
      #
      @config = DEFAULTS.merge file_config.merge(cli_options)

      @config[:css_dir]    = File.expand_path(@config[:css_dir])
      @config[:js_dir]     = File.expand_path(@config[:js_dir])
      @config[:svg_dir]    = File.expand_path(@config[:svg_dir])
      @config[:output_dir] = File.expand_path(@config[:output_dir])
      @config[:npm_dir]    = File.expand_path(@config[:npm_dir])

      FileUtils.mkdir_p(@config[:output_dir])

      @config
    end
  end

  def read_config(file)
    file = File.expand_path(file || DEFAULTS[:config_file])

    if File.exist?(file)
      symbolize(YAML.load(File.read(file)))
    else
      {}
    end
  end

  def build
    threads = []

    threads << Thread.new { build_svg } if config[:build_svg]
    threads << Thread.new { build_js  } if config[:build_js]
    threads << Thread.new { build_css } if config[:build_css]

    threads.each { |thr| thr.join }
  end

  def watch
    threads = []

    threads << listen(:svg, :build_svg) if config[:build_svg]
    threads << watch_js                          if config[:build_js]
    threads << listen(:css, :build_css) if config[:build_css]

    threads.each { |thr| thr.join }
  end

  def build_js
    return unless File.directory?(config[:js_dir])

    file = File.join(config[:js_dir], 'index.js')

    if File.exist?(file)
      dest = destination(file).sub(/\.js/,'')

      command = "#{File.join(config[:npm_dir], ".bin/browserify")} #{file} -t "
      + "babelify --standalone #{config[:js_module_name]} -o #{dest}.js "
      + "-d -p [ minifyify --map #{File.basename(output_dir)}.map.json --output #{dest}.map.json ]"

      system command
    end
  end

  def destination(file)
    if config[:version]
      file = file.sub(/(\.\w+)$/, '-'+config[:version]+'\1')
    end

    File.join(config[:output_dir], File.basename(file))
  end

  def build_svg
    return unless File.directory?(config[:svg_dir])

    require 'esvg'

    if @svg.nil?
      @svg = Esvg::SVG.new(config_file: config[:config_file], cli: true, optimize: true)
    else
      @svg.read_files
    end

    @svg.write
  end

  def build_css
    return unless File.directory?(config[:css_dir])

    style = 'nested'
    sourcemap = 'none'

    if ENV['CI'] || ENV['RAILS_ENV'] == 'production'
      style = "compressed"
      sourcemap = 'auto'
    end

    css_files.each do |file|
      dest = destination(file).sub(/scss$/,'css')
      system "sass #{file}:#{dest} --style #{style} --sourcemap=#{sourcemap}"

      post_css = File.join(config[:npm_dir], "postcss-cli/bin/postcss")
      system "#{post_css} --use autoprefixer #{dest} -o #{dest}"
      puts "Built: #{dest}"
    end
  end

  def css_files
    Dir[File.join(config[:css_dir], '*.scss')].reject {|f| f.start_with?('_') }
  end

  def watch_js
    file = File.join(config[:js_dir], 'index.js')

    Thread.new {
      watchify = File.join(config[:npm_dir], ".bin/watchify")

      command = "#{watchify} #{file} --poll --debug -t "
      + "babelify #{config[:js_module_name] || config[:app_name]} -o #{destination(file)} -v"

      system command
    }
  end

  def listen(type, method)
    require 'listen'

    Thread.new {
      listener = Listen.to(config["#{type}_dir".to_sym], only: /#{type}$/) do |modified, added, removed|
        self.public_send(method)
      end

      self.public_send(method)

      puts "#{type.upcase} Build complete. Listening for changes..."

      listener.start # not blocking
      sleep
    }
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

  def symbolize(obj)
    if obj.is_a? Hash
      return obj.inject({}) do |memo, (k, v)|
        memo.tap { |m| m[k.to_sym] = symbolize(v) }
      end
    elsif obj.is_a? Array
      return obj.map { |memo| symbolize(memo) }
    end
    obj
  end
end
