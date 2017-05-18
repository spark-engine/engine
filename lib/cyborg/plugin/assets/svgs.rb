module Cyborg
  module Assets
    class Svgs < AssetType

      def initialize(plugin, path)

        require 'cyborg/esvg'

        @plugin = plugin
        @base = path

      end

      def icons
        @svg ||= Esvg::SVG.new({
          config_file: File.join(plugin.root, 'config', 'esvg.yml'),
          source: @base,
          assets: plugin.paths[:javascripts],
          version: plugin.version,
          build: plugin.destination,
          temp: Cyborg.rails_path('tmp/cache/assets'),
          filename: '_icons.js',
          compress: Cyborg.production?,
          optimize: true,
          print: false
        })

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

      def use(*args)
        icons.use(*args)
      end

      def build_paths
        icons.build_paths.map { |file| file.sub("-#{plugin.version}",'') }
      end

      def build

        begin
          icons.read_files

          return if icons.svgs.empty?

          if files = icons.build
            files.each do |file|
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
