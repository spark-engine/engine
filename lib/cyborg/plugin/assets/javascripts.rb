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

            dest = destination(file)

            FileUtils.rm dest

            response = Open3.capture3(build_command(file))

            if File.exist?(dest) && !File.read(dest).strip.empty?
              compress(dest) if Cyborg.production?
              build_success file
            else
              build_failure file

              response = response.map { |l| l.to_s.split("\n") }.flatten

              response.each do |line|
                if !line.empty? &&
                   !line.match(/node_modules/i) &&
                   !line.match(/pid (\d+?) exit/i) &&
                   !line.match(/\[BABEL\] Note:/i)
                  log_error line.gsub(plugin.root+'/','')
                end
              end

              puts ""
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
