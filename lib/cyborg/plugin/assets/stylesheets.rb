require 'sass'
require "autoprefixer-rails"

module Cyborg
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

          if File.extname(file).match(/\.css/)
            build_css(file)
          elsif File.extname(file).match(/\.s[ca]ss/)
            build_sass(file)
          end

          if File.exist? destination(file)
            puts build_msg(file)
          else
            puts "FAILED TO WRITE: #{file}"
          end
        end
      end

      def build_css(file)
        css = AutoprefixerRails.process(File.read(file)).css
        File.open(destination(file), 'w') { |io| io.write(css) }

        compress(destination(file))
      end

      def build_sass(file)
        style = Cyborg.production? ? "compressed" : 'nested'

        dest = destination(file)

        css = Sass.compile_file(file, style: style)
        css = AutoprefixerRails.process(css).css

        File.open(dest, 'w') { |io| io.write(css) }

        compress(dest)
      end

      # Convert extension
      def versioned(file)
        super(file.sub(/(\.css)?\.s[ca]ss$/i,'.css'))
      end
    end
  end
end

