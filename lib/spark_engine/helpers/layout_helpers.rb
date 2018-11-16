module SparkEngine
  module Helpers
    module LayoutHelper
      def render_layout(*args, &block)
        options = {
          locals: args.last.is_a?(Hash) ? args.pop : {}
        }
        options[:template] = "layouts/#{args.first}"

        yield if block_given?
        render options
      end

      def javascripts(&block)
        content_for :javascripts, &block
      end

      def stylesheets(&block)
        content_for :stylesheets, &block
      end

      # Make it easy to assign body classes from views
      def root_class(classnames=nil)
        unless classnames.nil?
          content_for(:spark_root_classes) do
            [classnames].flatten.join(' ') + ' '
          end
        end
        if classes = content_for(:spark_root_classes)
          classes.strip
        end
      end

    end
  end
end
