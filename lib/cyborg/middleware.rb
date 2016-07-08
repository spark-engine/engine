require 'rack/cors'

module Cyborg
  class Application < Rails::Application
    config.middleware.insert_before ActionDispatch::Static, Rack::Deflater

    config.middleware.insert_before 0, "Rack::Cors", :debug => true, :logger => (-> { Rails.logger }) do
      allow do
        origins "*"
        resource "*", {
          :headers => :any,
          :expose => ["Location"],
          :methods => [:get, :post, :put, :patch, :delete, :options]
        }
      end
    end
  end
end
