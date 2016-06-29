module Megatron
  module Helpers
    module AssetsHelper

      def get_asset_path(asset)
        host = Megatron.production? ? ENV['ASSETS_CDN'] || config[:assets_cdn] : '/'

        File.join(host, asset)
      end

      def asset_tags
        tags = ''

        Megatron.plugins.each do |plugin|
          plugin.javascripts.urls.each do |url|
            tags += javascript_include_tag(url)
          end
          plugin.stylesheets.urls.each do |url|
            tags += stylesheet_link_tag(url)
          end
        end

        tags.html_safe
      end

      def all_asset_tags
        version = if params[:__asset_version]
          "-#{params[:__asset_version]}"
        else
          "-#{Gondor::VERSION}"
        end

        ext_suffix = Megatron.production? ? '.gz' : ''

        pin_tab_icon(
          get_asset_path('logo.svg')
        ) +
        favicon_link_tag(
          get_asset_path('favicon.ico'), sizes: "32x32"
        ) +
        # TODO: iterate through stylesheets and javascripts
        stylesheet_link_tag(
          get_asset_path("gondor#{version}.css#{ext_suffix}")
        ) +
        javascript_include_tag(
          get_asset_path("gondor#{version}.js#{ext_suffix}")
        )
      end

      def pin_tab_icon(path)
        %Q{<link rel="mask-icon" mask href="#{path}" color="black">}.html_safe
      end

      def error_asset_tag
        version = Gondor::VERSION
        ext_suffix = Megatron.production? ? '.gz' : ''

        # Embed styles directly for these error codes since they are served from haproxy
        # and are likely to be served when the stylesheet server cannot be reached
        #
        if [408, 502, 503, 504].include?(@status_code)
          style== File.read("../public/assets/gondor/gondor-error-pages-#{version}.css")
        else
          stylesheet_link_tag(
            get_asset_path("gondor-error-pages-#{version}.css#{ext_suffix}")
          )
        end
      end
    end
  end
end

