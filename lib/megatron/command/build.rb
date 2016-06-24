module Megatron
  module Build
    extend self

    def config
      Megatron.config
    end

    def run
      threads = []
      FileUtils.mkdir_p(config[:paths][:output])

      config[:assets].each do |asset|
        threads << Thread.new { self.public_send(asset.to_sym) }
      end

      threads.each { |thr| thr.join }
    end


    def javascripts
      browserfy = '$(npm bin)/browserify'

      if `#{browserify}`.emtpy?
        puts "BUILD FAILED: Browserfy NPM module not found."
        puts "Please add browserify to your package.json and run `npm install`"
        exit!
      end

      Dir[File.join(config[:paths][:javascripts], '*.js')].each do |file|
        dest = Assets.destination(file).sub(/\.js/,'')

        command = "#{browserfy} #{file} -t "
        command += "babelify --standalone #{config[:js_name]} -o #{dest}.js "
        command += "-d -p [ minifyify --map #{File.basename(dest)}.map.json --output #{dest}.map.json ]"

        system command
        puts "Built: #{relative_path(dest+'.js')}"
      end
    end

    def svgs
      require 'esvg'

      if @svg.nil?
        @svg = Esvg::SVG.new({
          config_file: File.join(config[:root], 'esvg.yml'),
          path: config[:paths][:svg],
          output_path: config[:paths][:javascripts],
          cli: true, 
          optimize: true
        })
      else
        @svg.read_files
      end

      @svg.write
    end

    def stylesheets
      style = 'nested'
      sourcemap = 'true'

      if Megatron.production?
        style = "compressed"
        sourcemap = 'auto'
      end

      post_css = '$(npm bin)/postcss'

      Assets.stylesheet_files.each do |file|
        dest = Assets.destination(file).sub(/(\.css)?\.s[ca]ss$/i,'.css')

        if file.end_with?('.css')
          system "cp #{file} #{dest}"
        else
          cmd = "sass #{file}:#{dest} --style #{style}"
          cmd += " --sourcemap" if sourcemap
          system cmd
        end

        unless `#{post_css}`.empty?
          system "#{post_css} --use autoprefixer #{dest} -o #{dest}"
        end

        puts "Built: #{relative_path(dest)}"
      end
    end

    def relative_path(path)
      path.sub(File.expand_path(Dir.pwd)+'/', '')
    end
  end
end
