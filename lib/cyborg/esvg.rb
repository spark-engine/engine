require 'esvg'

module Esvg
  module Helpers

    def use_svg(name, options={}, &block)

      if block_given?
        options[:content] = content_tag(:g, {}, &block).to_s
      end

      if esvg_files.exist?(name, options[:fallback])
        esvg_files.use(name, options).html_safe
      elsif Cyborg.plugin.svgs.icons.exist?(name, options[:fallback])
        Cyborg.plugin.svgs.use(name, options).html_safe
      end
    end
  end
end
