module Megatron
  module Assets
    class Svgs < AssetType

      def initialize(plugin, path)
        require 'esvg'
        @plugin = plugin
        @base = path

        @svg = Esvg::SVG.new({
          config_file: File.join(plugin.root, 'esvg.yml'),
          path: path,
          tmp_path: File.join(Megatron.rails_path, 'tmp/cache/assets'),
          js_path: File.join(plugin.paths[:javascripts], '_svg.js'),
          optimize: true
        })
      end

      def build
        @svg.read_files
        if write_path = @svg.write
          puts "Built: #{write_path.sub(plugin.root+'/','')}"
        end
      end
    end
  end
end
