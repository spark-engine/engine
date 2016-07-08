module Cyborg
  module Helpers
    module AssetsHelper

      def get_asset_path(asset)
        host = Cyborg.production? ? ENV['ASSETS_CDN'] || config[:assets_cdn] : '/'

        File.join(host, asset)
      end

      def asset_tags
        tags = ''

        Cyborg.plugins.each do |plugin|
          plugin.javascripts.urls.each do |url|
            tags += javascript_include_tag(url)
          end
          plugin.stylesheets.urls.each do |url|
            tags += stylesheet_link_tag(url)
          end
        end

        tags.html_safe
      end

      def pin_tab_icon(path)
        %Q{<link rel="mask-icon" mask href="#{path}" color="black">}.html_safe
      end
    end
  end
end

