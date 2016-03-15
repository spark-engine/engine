module Positron
  module Build
    extend self

    def config
      Positron.config
    end

    def run
      threads = []

      config[:assets].each do |asset|
        threads << Thread.new { self.public_send(asset.to_sym) }
      end

      threads.each { |thr| thr.join }
    end


    def js
      return unless File.directory?(config[:js_dir])

      file = File.join(config[:js_dir], 'index.js')

      if File.exist?(file)
        dest = destination(file).sub(/\.js/,'')

        command = "#{File.join(config[:npm_dir], ".bin/browserify")} #{file} -t "
        command += "babelify --standalone #{config[:js_module_name]} -o #{dest}.js "
        command += "-d -p [ minifyify --map #{File.basename(dest)}.map.json --output #{dest}.map.json ]"

        system command
        puts "Built: #{relative_path(dest+'.js')}"
      end
    end

    def svg
      return unless File.directory?(config[:svg_dir])

      require 'esvg'

      if @svg.nil?
        @svg = Esvg::SVG.new(config_file: config[:config_file], cli: true, optimize: true)
      else
        @svg.read_files
      end

      @svg.write
    end

    def sass
      return unless File.directory?(config[:sass_dir])

      style = 'nested'
      sourcemap = 'none'

      if ENV['CI'] || ENV['RAILS_ENV'] == 'production'
        style = "compressed"
        sourcemap = 'auto'
      end

      sass_files.each do |file|
        dest = destination(file).sub(/scss$/,'css')
        system "sass #{file}:#{dest} --style #{style} --sourcemap=#{sourcemap}"

        post_css = File.join(config[:npm_dir], "postcss-cli/bin/postcss")
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
      Dir[File.join(config[:sass_dir], '*.scss')].reject {|f| f.start_with?('_') }
    end

    def relative_path(path)
      path.sub(File.expand_path(Dir.pwd)+'/', '')
    end
  end
end
