require 'spark_engine'
require '<%= @gem %>/version'

module <%= @gem_module %>
  class Plugin < SparkEngine::Plugin
  end
end

plugin_options = {
  gem: '<%= @gem %>'<% unless @engine.nil? %>,
  engine: '<%= @engine %>'<% end %>
}

SparkEngine.register(<%= @gem_module %>::Plugin, plugin_options) do
  # Customize Engine here. 
  # This block is evaluated when Engine is created.
end
