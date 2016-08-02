module Cyborg
  module Helpers
    module LayoutHelper
      def render_layout(*args, &block)
        options = args.last.is_a?(Hash) ? args.pop : {}
        layout = args.first || 'application'
        yield
        render template: "layouts/#{Cyborg.plugin.name}/#{layout}"
      end

      def javascripts(&block)
        content_for :javascripts, &block
      end

      def stylesheets(&block)
        content_for :stylesheets, &block
      end
    end
  end
end

