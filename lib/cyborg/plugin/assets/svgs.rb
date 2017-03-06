module Cyborg
  module Assets
    class Svgs < AssetType

      def initialize(plugin, path)
        require 'esvg'
        @plugin = plugin
        @base = path

        return if find_files.empty?

        @svg = Esvg.new({
          config_file: File.join(plugin.root, 'config', 'esvg.yml'),
          path: path,
          tmp_path: Cyborg.rails_path('tmp/cache/assets'),
          js_path: File.join(plugin.paths[:javascripts], '_svg.js'),
          optimize: true
        })
      end

      def icons
        @svg
      end

      def ext
        "svg"
      end

      def build
        return if find_files.empty?

        begin
          @svg.read_files

          if file = @svg.write
            puts build_success(file)
          else
            log_error "FAILED TO BUILD SVGs"
          end
        rescue => bang
          log_error "FAILED TO BUILD SVGs"
          log_error bang
        end
      end
    end
  end
end
