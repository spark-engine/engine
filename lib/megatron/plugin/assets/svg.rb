module Megatron
  module Assets
    class Svg
      @@type = :svgs
      @@extension = 'svg'

      def initialize(plugin)
        require 'esvg'

        @svg = Esvg::SVG.new({
          config_file: File.join(plugin.root, 'esvg.yml'),
          path: plugin.paths[:svgs],
          output_path: plugins.paths[:javascripts],
          cli: true,
          optimize: true
        })
      end

      def build
        @svg.read_files
        @svg.write
      end
    end
  end
end
