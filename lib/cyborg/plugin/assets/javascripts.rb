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
            begin
              system build_command(file)
              compress(destination(file)) if Cyborg.production?

              puts build_success(file)

            rescue => bang
              build_failure file
              log_error bang
            end
          end
        else
          log_error "JS BUILD FAILED: browserifyinc NPM module not found.\n" << "Please add browserifyinc to your package.json and run `npm install`"
          abort
        end
      end

      def npm_path( cmd )
        File.join Cyborg.gem_path, "node_modules/.bin", cmd
      end

      def build_command(file)
        dest = destination(file).sub(/\.js$/,'')
        options = " -t babelify --standalone #{plugin.name} -o #{dest}.js -d"

        cmd = if Cyborg.production?
          npm_path "browserify #{file} #{options}"
        else
          npm_path "browserifyinc --cachefile #{cache_file(File.basename(dest))} #{file} #{options}"
        end

        if Cyborg.production?
          cmd += " -p [ minifyify --map #{url(file).sub(/\.js$/,'')}.map.json --output #{dest}.map.json ]"
        end

        cmd
      end
    end
  end
end
