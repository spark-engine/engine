module Cyborg
  module Assets
    class Javascripts < AssetType
      def ext
        "js"
      end

      def asset_tag(*args)
        javascript_include_tag(args)
      end

      def cache_file(name=nil)
        Cyborg.rails_path("tmp/cache/assets/.browserify-cache-#{name}.json")
      end

      def build
        files = find_files
        FileUtils.mkdir_p(File.dirname(cache_file)) if !files.empty?

        if Open3.capture3("npm ls browserify-incremental")[1].empty?
          files.each do |file|
            system build_command(file)

            if Cyborg.production?
              compress(destination(file))
            end

            puts build_msg(file)
          end
        else
          abort "JS BUILD FAILED: browserifyinc NPM module not found.\n" << "Please add browserifyinc to your package.json and run `npm install`"
        end
      end

      def build_command(file)
        dest = destination(file).sub(/\.js$/,'')
        options = " -t babelify --standalone #{plugin.name} -o #{dest}.js -d"

        cmd = if Cyborg.production?
          "browserify #{file} #{options}"
        else
          "browserifyinc --cachefile #{cache_file(File.basename(dest))} #{file} #{options}"
        end

        if Cyborg.production? || plugin.maps?
          cmd += " -p [ minifyify --map #{url(file).sub(/\.js$/,'')}.map.json --output #{dest}.map.json ]"
        end

        cmd
      end
    end
  end
end
