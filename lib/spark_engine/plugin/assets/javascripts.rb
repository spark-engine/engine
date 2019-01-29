module SparkEngine
  module Assets
    class Javascripts < AssetType
      def ext
        "js"
      end

      def asset_tag(*args)
        javascript_include_tag(args)
      end

      def cache_file(name=nil)
        SparkEngine.rails_path("tmp/cache/assets/.browserify-cache-#{name}.json")
      end

      # Find all asset files matching array of names
      def filter_files(names)
        [find_files, plugin.svgs.build_paths].flatten.select do |f|
          names.include? File.basename(f).sub(/(\..+)$/,'')
        end
      end

      def build
        files = find_files
        FileUtils.mkdir_p(File.dirname(cache_file)) if !files.empty?

        if Open3.capture3("npm ls browserify-incremental")[1].empty?
          files.each do |file|

            dest = destination(file)

            FileUtils.rm(dest) if File.exists?(dest)

            response = Open3.capture3(build_command(file))

            # If the file exists and is not empty (a failed build is empty)
            if File.exist?(dest) && !File.read(dest).strip.empty?
              compress(dest) if SparkEngine.production?
              build_success file
            else
              build_failure file

              response = response.map { |l| l.to_s.split("\n") }.flatten

              response.each do |line|
                if !line.empty? &&                      # Don't print empty lines
                   !line.match(/node_modules/i) &&      # Ignore stack traces from installed modules
                   !line.match(/pid (\d+?) exit/i) &&   # Ignore pid exit stack line
                   !line.match(/\[BABEL\] Note:/i)      # Notices from Bable are noisy
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
        File.join SparkEngine.gem_path, "node_modules/.bin", cmd
      end

      def build_command(file)
        dest = destination(file)
        basename = pathname(file)
        options = "--standalone #{plugin.name} -d"

        cmd = if SparkEngine.production?
                npm_path %Q{browserify #{file} #{options} | #{npm_path('uglifyjs')} --output #{dest} --source-map "url='#{basename}.map',filename='#{basename}',content='inline',includeSources='true'"}
              else
                npm_path "browserify #{file} #{options} > #{dest}"
              end
        puts "Running: #{cmd}"

        cmd

      end
    end
  end
end
