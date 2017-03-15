require 'rack/cors'
require 'action_dispatch/middleware/static'

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

    # Rails 5 middleware patch
    if Cyborg.rails5?

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

    # Rails 4 middleware patch
    else

      def initialize(app, path, cache_control=nil, engine_name: nil)
        @app = app
        @engine_name = engine_name
        @file_handler = ::ActionDispatch::FileHandler.new(path, cache_control)
      end

      def call(env)
        prefix = File.join Application.config.assets.prefix, @engine_name

        case env['REQUEST_METHOD']
        when 'GET', 'HEAD'
          path = env['PATH_INFO'].chomp('/')

          if path.start_with? prefix
            path = path.remove /\A#{prefix}\//

            if match = @file_handler.match?(path)
              env["PATH_INFO"] = match
              return @file_handler.call(env)
            end
          end
        end

        @app.call(env)
      end
    end
  end

end
