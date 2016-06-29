module Megatron
  module Assets
    class Javascripts < AssetType
      def ext
        "js"
      end

      def build
        if npm_module_installed "browserify"
          find_files.each do |file|
            dest = destination(file).sub(/\.js$/,'')
            npm_sh "browserify #{file} -t babelify --standalone #{plugin.module_name} -o #{dest}.js -d -p [ minifyify --map #{url(file)}.map.json --output #{dest}.map.json ]"
            puts build_msg(file)
          end
        else
          puts "BUILD FAILED: Browserfy NPM module not found."
          puts "Please add browserify to your package.json and run `npm install`"
          exit!
        end
      end
    end
  end
end
