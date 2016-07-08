module Cyborg
  module Assets
    class Javascripts < AssetType
      def ext
        "js"
      end

      def build
        if find_node_module "browserify"
          find_files.each do |file|
            dest = destination(file).sub(/\.js$/,'')
            npm_command "browserify #{file} -t babelify --standalone #{plugin.module_name} -o #{dest}.js -d -p [ minifyify --map #{url(file)}.map.json --output #{dest}.map.json ]"
            puts build_msg(file)
          end
        else
          abort "JS BUILD FAILED: browserify NPM module not found.\n" << "Please add browserify to your package.json and run `npm install`"
        end
      end
    end
  end
end
