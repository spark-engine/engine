require 'esvg'

module Esvg
  module Helpers

    def use_svg(name, options={}, &block)
      files = if esvg.exist?(name, options[:fallback])
        esvg
      elsif Cyborg.plugin.svgs.esvg.exist?(name, options[:fallback])
        Cyborg.plugin.svgs.esvg
      end

      use_svg_with_files(files, name, options, &block) if files
    end
  end
end
