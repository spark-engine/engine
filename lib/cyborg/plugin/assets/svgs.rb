module Cyborg
  module Assets
    class Svgs < AssetType

      def initialize(plugin, path)
        require 'esvg'
        @plugin = plugin
        @base = path

        @svg = Esvg::SVG.new({
          config_file: File.join(plugin.root, 'config', 'esvg.yml'),
          path: path,
          tmp_path: Cyborg.rails_path('tmp/cache/assets'),
          js_path: File.join(plugin.paths[:javascripts], '_icons.js'),
          js_build_version: plugin.version,
          js_build_dir: plugin.destination,
          optimize: true
        })

      end

      def icons
        @svg
      end

      def ext
        "svg"
      end

      def local_path(path)
        path = File.expand_path(path)

        # Strip all irrelevant sections of the path
        path.sub(plugin.paths[:javascripts]+'/', '') # written to assets dir
            .sub(plugin.root+'/','')                 # writtent to public dir
      end

      def build_paths
        @svg.build_paths.map { |file| file.sub("-#{plugin.version}",'') }
      end

      def build

        begin
          @svg.read_files

          return if @svg.files.empty?

          if files = @svg.write
            files.each do |file|
              if file.start_with?(plugin.destination)
                compress(file)
              end
              puts build_success(file)
            end
          else
            log_error "FAILED TO BUILD SVGs"
          end
        rescue Exception => e
          log_error "\nFAILED TO BUILD SVGs"

          if e.backtrace && e.backtrace.is_a?(Array)
            log_error "Error in file: #{local_path(e.backtrace.shift)}"

            e.backtrace.each do |line|
              log_error local_path(line)
            end
          end

          log_error("  #{e.message}\n") if e.message

        end
      end
    end
  end
end
