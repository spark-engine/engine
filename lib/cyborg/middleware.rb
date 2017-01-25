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
  class StaticAssets
    def initialize(app, path, index: 'index', headers: {}, engine_name: nil)
      @app = app
      @engine_name = engine_name
      @file_handler = ActionDispatch::FileHandler.new(path, index: index, headers: headers)
    end

    def call(env)
      req = Rack::Request.new env
      prefix = File.join Application.config.assets.prefix, @engine_name

      if req.get? || req.head?
        path = req.path_info.chomp('/'.freeze)

        if path.start_with? prefix
          path = path.remove /\A#{prefix}\//

          if match = @file_handler.match?(path)
            req.path_info = match
            return @file_handler.serve(req)
          end
        end
      end

      @app.call(req.env)
    end
  end
end
