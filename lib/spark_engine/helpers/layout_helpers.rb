module SparkEngine
  module Helpers
    module LayoutHelper
      def render_layout(*args, &block)
        options = args.last.is_a?(Hash) ? args.pop : {}
        options[:template] = "layouts/#{args.first}"
        options[:locals] ||= {}
        options[:locals][:classes] = [options.delete(:classes)].flatten

        yield if block_given?
        render options
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
