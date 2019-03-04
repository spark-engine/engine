module SparkEngine
  class Plugin
    attr_reader   :name, :gem, :engine,
                  :stylesheets, :javascripts, :svgs, :destination

    def initialize(options)
      @name            = options.delete(:engine).downcase
      @gem             = Gem.loaded_specs[options.delete(:gem)]
      config(options)
      expand_asset_paths

      # Store the gem path for access later when overriding root
      parent_module.instance_variable_set(:@gem_path, root)
      parent_module.instance_variable_set(:@spark_plugin_name, name)
      add_assets
    end

    def engine_name
      @engine.name.sub(/::Engine/,'')
    end

    # Create a new Rails::Engine
    def create_engine(&block)
      @engine = parent_module.const_set('Engine', Class.new(Rails::Engine) do

        def spark_plugin_path
          parent = Object.const_get(self.class.name.sub(/::Engine/,''))
          Pathname.new parent.instance_variable_get("@gem_path")
        end

        def config
          @config ||= Rails::Engine::Configuration.new(spark_plugin_path)
        end

        engine_name SparkEngine.plugin.name

        require 'spark_engine/middleware'

        # Ensure compiled assets in /public are served
        initializer "#{name}.static_assets" do |app|
          if app.config.public_file_server.enabled
            app.middleware.insert_after ::ActionDispatch::Static, SparkEngine::StaticAssets, "#{root}/public", engine_name: SparkEngine.plugin.name
            app.middleware.insert_before ::ActionDispatch::Static, Rack::Deflater
          end
        end

        # Ensure Components are readable from engine paths
        initializer "#{name}.view_paths" do |app|
          ActiveSupport.on_load :action_controller do
            append_view_path "#{SparkEngine.plugin.paths[:components]}"
          end

          # Inject Sass importer for yaml files
          if defined?(SassC) && defined?(SassC::Rails)
            SassC::Rails::Importer::EXTENSIONS << SassC::SparkEngine::SassYamlExtension.new
          end

        end

      end)

      # Autoload engine lib
      @engine.config.autoload_paths << File.join(@engine.spark_plugin_path, "lib")

      # Autoload components
      @engine.config.autoload_paths << SparkEngine.plugin.paths[:components]

      # Takes a block passed an evaluates it in the context of a Rails engine
      # This allows plugins to modify engines when created.
      @engine.instance_eval(&block) if block_given?
    end

    def parent_module
      mods = self.class.to_s.split('::')
      mods.pop
      Object.const_get(mods.join('::'))
    end

    def add_assets
      @javascripts = Assets::Javascripts.new(self, paths[:javascripts])
      @stylesheets = Assets::Stylesheets.new(self, paths[:stylesheets])
      @svgs        = Assets::Svgs.new(self, paths[:svgs])
    end

    def assets(options={})
      assets = []
      if options[:select_assets]
        assets.push @svgs if options[:svg]
        assets.push @stylesheets if options[:css]
        assets.push @javascripts if options[:js]
      else
        assets = [@svgs, @stylesheets, @javascripts]
      end

      assets
    end

    def svgs?
      @svgs.icons.nil?
    end

    def build(options={})
      FileUtils.mkdir_p(asset_path)
      assets(options).each do |asset|
        asset.build
      end
    end

    def watch(options)
      assets(options).map(&:watch)
    end

    def asset_root
      asset_prefix = Rails.application.config.assets.prefix || '/assets'
      File.join asset_prefix, name
    end

    def production_root
      @production_asset_root ||= asset_root
    end

    def config(options)

      options = {
        production_asset_root: nil,
        destination:   "public/",
        root:          @gem.full_gem_path,
        version:       @gem.version.to_s,
        gem_name:      @gem.name,
        paths: {
          stylesheets: "app/assets/stylesheets/#{name}",
          javascripts: "app/assets/javascripts/#{name}",
          components:  "app/components/#{name}",
          images:      "app/assets/images/#{name}",
          svgs:        "app/assets/svgs/#{name}",
        }
      }.merge(options)

      options.each do |k,v|
        set_instance(k.to_s,v)
      end
    end

    def expand_asset_paths
      @paths.each do |type, path|
        @paths[type] = File.join(root, path)
      end
      @destination = File.join(root, @destination)
    end

    def asset_path(file=nil)
      dest = destination
      dest = File.join(dest, file) if file
      dest
    end

    def asset_url(file=nil)

      path = if SparkEngine.production? && !ENV[name.upcase + '_FORCE_LOCAL_ASSETS']
        production_root
      else
        asset_root
      end

      path = File.join(path, file) if file
      path
    end

    private

    def asset_ext(klass)
      klass.name.split('::').last.downcase
    end

    # Find files based on class type and
    # return an array of Classes for each file
    def add_files(klass)
      ext = asset_ext klass
      find_files(ext).map do |path|
        klass.new(self, path)
      end
    end

    # Find files by class type and extension
    def find_files(ext)
      files = Dir[File.join(paths[ext.to_sym], asset_glob(ext))]

      # Filter out partials
      files.reject { |f| File.basename(f).start_with?('_') }
    end

    def asset_glob(type)
      case type
      when "sass"
        "*.s[ca]ss"
      else
        "*.#{type}"
      end
    end

    # Convert configuration into instance variables
    def set_instance(name, value)
      instance_variable_set("@#{name}", value)

      instance_eval(<<-EOS, __FILE__, __LINE__ + 1)
        def #{name}
          @#{name}
        end
      EOS
    end

  end
end
