module Cyborg
  module Helpers
    module LayoutHelper
      def layout(name, options={}, &block)
        layout = options.delete(:layout) || 'application'
        yield
        render template: "layouts/#{name}/#{layout}"
      end

      def javascripts(&block)
        content_for :javascripts, &block
      end

      def stylesheets(&block)
        content_for :stylesheets, &block
      end

      def main(options={}, &block)
        content_for :main, &block
      end

      def sidebar(&block)
        content_for :sidebar, &block
      end
    end
  end
end

