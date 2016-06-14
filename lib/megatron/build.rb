module Megatron
  module Build
    extend self

    def config
      Megatron.config
    end

    def run
      threads = []

      config[:assets].each do |asset|
        threads << Thread.new { self.public_send(asset.to_sym) }
      end

      threads.each { |thr| thr.join }
    end


    def javascripts
      browserfy = File.join(config[:npm_dir], 'node_modules', ".bin/browserify")
      file = File.join(config[:javascripts_dir], 'index.js')

      if !File.exist?(browserfy)
        puts "BUILD FAILED: Browserfy NPM module not found at #{relative_path(browserfy)}."
        puts "Please configure `npm_dir` in megatron.yml, or install with `megatron npm`"
        exit!
      end

      if File.exist?(file)
        dest = destination(file).sub(/\.js/,'')

        command = "#{browserfy} #{file} -t "
        command += "babelify --standalone #{config[:js_module_name]} -o #{dest}.js "
        command += "-d -p [ minifyify --map #{File.basename(dest)}.map.json --output #{dest}.map.json ]"

        system command
        puts "Built: #{relative_path(dest+'.js')}"
      end
    end

    def svg
      require 'esvg'

      if @svg.nil?
        @svg = Esvg::SVG.new(config_file: config[:config_file], path: config[:svg_dir], output_path: config[:javascripts_dir], cli: true, optimize: true)
      else
        @svg.read_files
      end

      @svg.write
    end

    def stylesheets
      style = 'nested'
      sourcemap = 'none'

      if ENV['CI'] || ENV['RAILS_ENV'] == 'production'
        style = "compressed"
        sourcemap = 'auto'
      end

      sass_files.each do |file|
        dest = destination(file).sub(/s[ca]ss$/,'css')
        system "sass #{file}:#{dest} --style #{style} --sourcemap=#{sourcemap}"

        post_css = File.join(config[:npm_dir], 'node_modules', "postcss-cli/bin/postcss")
        system "#{post_css} --use autoprefixer #{dest} -o #{dest}"
        puts "Built: #{relative_path(dest)}"
      end
    end

    def destination(file)
      if config[:version]
        file = file.sub(/(\.\w+)$/, '-'+config[:version]+'\1')
      end

      File.join(config[:output_dir], File.basename(file))
    end

    def sass_files
      Dir[File.join(config[:stylesheets_dir], '*.scss')].reject {|f| File.basename(f).start_with?('_') }
    end

    def relative_path(path)
      path.sub(File.expand_path(Dir.pwd)+'/', '')
    end
  end
end
