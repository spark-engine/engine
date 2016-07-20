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

          puts build_msg(file)
        end
      end

      def build_css(file)
        system "cp #{file} #{destination(file)}"
        compress(destination(file))
      end

      def build_sass(file)
        style = Cyborg.production? ? "compressed" : 'nested'
        sourcemap = plugin.maps? ? 'auto' : 'false'

        dest = destination(file)

        system "sass #{file}:#{dest} --style #{style} --sourcemap=#{sourcemap}"

        dest = destination(file) 
        npm_command "postcss --use autoprefixer #{dest} -o #{dest}"
        compress(dest)
      end


      # Convert extension
      def versioned(file)
        super(file.sub(/(\.css)?\.s[ca]ss$/i,'.css'))
      end
    end
  end
end

