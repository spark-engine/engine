require 'action_dispatch/middleware/static'

module SparkEngine
  class Application < Rails::Application
    initializer "static assets" do |app|
      app.middleware.insert_before(::ActionDispatch::Static, ::ActionDispatch::Static, "#{root}/public")
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
