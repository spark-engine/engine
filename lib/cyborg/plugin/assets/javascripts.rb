module Cyborg
  module Assets
    class Javascripts < AssetType
      def ext
        "js"
      end

      def asset_tag(*args)
        javascript_include_tag(args)
      end

      def build
        if Open3.capture3("npm ls browserify-incremental")[1].empty?
          find_files.each do |file|
            dest = destination(file).sub(/\.js$/,'')
            cmd = "browserifyinc --cachefile #{Cyborg.rails_path("tmp/cache/assets/.browserify-cache.json")} #{file} -t babelify --standalone #{plugin.module_name} -o #{dest}.js -d"
            cmd += "-p [ minifyify --map #{url(file).sub(/\.js$/,'')}.map.json --output #{dest}.map.json ]" if plugin.maps? || Cyborg.production?
            system cmd
            puts build_msg(file)
          end
        else
          abort "JS BUILD FAILED: browserifyinc NPM module not found.\n" << "Please add browserifyinc to your package.json and run `npm install`"
        end
      end
    end
  end
end
