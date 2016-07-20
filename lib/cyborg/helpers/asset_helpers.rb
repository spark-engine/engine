module Cyborg
  module Helpers
    module AssetsHelper

      def stylesheet_tag(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        tags = ''

        stylesheet_url(args).each do |url|
          url += '.gz' if Cyborg.production?
          tags += stylesheet_link_tag(url, options)
        end

        tags.html_safe
      end

      def javascript_tag(*args)
        options = args.last.is_a?(Hash) ? args.pop : {}
        tags = ''

        puts "searching for: #{javascript_url(args)}"
        javascript_url(args).each do |url|
          url += '.gz' if Cyborg.production?
          tags += javascript_include_tag(url, options)
        end

        tags.html_safe
      end

      def stylesheet_url(*args)
        Cyborg.plugin.stylesheets.urls(args)
      end

      def javascript_url(*args)
        Cyborg.plugin.javascripts.urls(args)
      end

      def asset_tags
        stylesheet_tag + javascript_tag
      end

      def pin_tab_icon(path)
        %Q{<link rel="mask-icon" mask href="#{path}" color="black">}.html_safe
      end
    end
  end
end

