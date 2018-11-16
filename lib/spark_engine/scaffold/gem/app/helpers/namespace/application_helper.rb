module <%= @plugin_module %>
  module ApplicationHelper

    # Make it easy to assign body classes from views
    def body_class(classnames=nil)
      unless classnames.nil?
        content_for(:body_classes) do
          [classnames].flatten.join(' ') + ' '
        end
      end
      if classes = content_for(:body_classes)
        classes.strip
      end
    end

  end
end
