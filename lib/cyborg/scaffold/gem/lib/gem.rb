require 'cyborg'
require '<%= @gem %>/version'

module <%= @gem_module %>
  class Plugin < Cyborg::Plugin
  end
end

Cyborg.register(<%= @gem_module %>::Plugin, {
  gem: '<%= @gem %>'<% unless @engine.nil? %>,
  engine: '<%= @engine %>'<% end %>
})
