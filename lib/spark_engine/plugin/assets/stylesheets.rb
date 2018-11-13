require 'sass'
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
        css = File.read(file)
        css = AutoprefixerRails.process().css if defined? AutoprefixerRails
        File.open(destination(file), 'w') { |io| io.write(css) }

        compress(destination(file))
      end

      def build_sass(file)
        style = SparkEngine.production? ? "compressed" : 'nested'
        dest = destination(file)

        Sass.logger.log_level = :error if SparkEngine.production?

        css = Sass.compile_file(file, style: style)
        css = AutoprefixerRails.process(css).css if defined? AutoprefixerRails

        File.open(dest, 'w') { |io| io.write(css) }

        compress(dest)
      end

      def data
        if @data
          @data
        else
          data = {}

          Dir[File.join(base, "**/*.yml")].each do |file|
            key = file.sub(base+"/", '').sub(/^_/,'').sub('.yml','')

            data[key] = SassParser.parse(file)
          end

          @data = data if SparkEngine.production?
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

