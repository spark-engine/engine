require 'spark_engine'
require '<%= @gem %>/version'

module <%= @gem_module %>
  class Plugin < SparkEngine::Plugin
  end
end

SparkEngine.register(<%= @gem_module %>::Plugin, {
  gem: '<%= @gem %>'<% unless @engine.nil? %>,
  engine: '<%= @engine %>'<% end %>
})
