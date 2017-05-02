module Cyborg
  module Assets
    class Svgs < AssetType

      def initialize(plugin, path)
        require 'esvg'
        @plugin = plugin
        @base = path

        @svg = Esvg.new({
          config_file: File.join(plugin.root, 'config', 'esvg.yml'),
          path: path,
          tmp_path: Cyborg.rails_path('tmp/cache/assets'),
          js_path: File.join(plugin.paths[:javascripts], '_icons.js'),
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
        File.expand_path(path).sub(plugin.paths[:javascripts], '').sub(/^\//,'')
      end

      def build

        begin
          @svg.read_files

          return if @svg.files.empty?

          if files = @svg.write
            files.each { |file| puts build_success(file) }
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
