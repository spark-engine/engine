begin
  require "autoprefixer-rails"
rescue
end

module SparkEngine
  module Assets
    class Stylesheets < AssetType

      def ext
        "*[ca]ss"
      end

      def autoprefixer_config
        @autoprefixer_config ||= begin
          config_path = File.join( SparkEngine.plugin.root, 'config', 'autoprefixer.yml' )
          if File.exist?( config_path )
            YAML.load_file( config_path ).deep_symbolize_keys
          else
            {}
          end
        end
      end

      def asset_tag(*args)
        stylesheet_link_tag(args)
      end

      def build(ext=nil)
        files = find_files
        files = files.reject {|f| !f.match(/\.#{ext}/) } if ext

        files.each do |file|

          begin
            if File.extname(file).match(/\.css/)
              build_css(file)
            elsif File.extname(file).match(/\.s[ca]ss/)
              build_sass(file)
            end

            puts build_success(file)

          rescue Exception => e
            build_failure file

            if e.backtrace.is_a? Array
              log_error "Error in file: #{local_path(e.backtrace[0])}"
            end

          log_error "  #{e.message}\n" if e.message
          end
        end
      end

      def build_css(file)
        css = prefix_css( File.read(file) )
        File.open(destination(file), 'w') { |io| io.write(css) }

        compress(destination(file))
      end

      def render_sass(file)
        require "spark_engine/sass/engine.rb"

        Sass.logger.log_level = :error if SparkEngine.production?
        Sass.compile_file(file, style: sass_style)
      end

      def render_sassc(file)
        require "spark_engine/sassc/importer"

        source = File.open(file, 'rb') { |f| f.read }
        options = {
          importer: SassC::SparkEngine::Importer,
          load_paths: load_paths,
          style: sass_style
        }

        SassC::Engine.new(source, options).render
      end

      def sass_style
        SparkEngine.production? ? "compressed" : 'nested'
      end

      def build_sass(file)
        css = prefix_css begin
          render_sassc(file)
        rescue LoadError => e
          render_sass(file)
        end

        dest = destination(file)

        File.open(dest, 'w') { |io| io.write(css) }
        compress(dest)
      end

      def load_paths
        [SparkEngine.plugin.paths[:stylesheets], SparkEngine.plugin.paths[:components]]
      end

      def prefix_css(css)
        if defined? AutoprefixerRails
          AutoprefixerRails.process(css, autoprefixer_config).css
        else
          css
        end
      end

      def data
        return @data if @data && SparkEngine.production?

        @data = Dir[File.join(base, "**/*.yml")].each_with_object({}) do |file, data|
          key = File.basename(file, '.*').sub(/^_/,'')
          data[key] = SassYaml.new(file: file).to_yaml
          data
        end
      end

      # Convert extension
      def versioned(file)
        super(file.sub(/(\.css)?\.s[ca]ss$/i,'.css'))
      end
    end
  end
end

