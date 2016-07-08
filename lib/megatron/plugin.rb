module Megatron
  class Plugin
    attr_reader   :module_name, :gem, :engine,
                  :stylesheets, :javascripts, :svgs, :destination

    def initialize(options)
      @name            = options.delete(:name) 
      @module_name     = parent_module.name
      @gem             = Gem.loaded_specs[@name]
      config(options)
      expand_asset_paths

      # Store the gem path for access later when overriding root
      parent_module.instance_variable_set(:@gem_path, root)
      add_assets

      @engine = create_engine if defined?(Rails)
    end

    def create_engine
      # Create a new Rails::Engine
      return parent_module.const_set('Engine', Class.new(Rails::Engine) do
        def get_plugin_path
          parent = Object.const_get(self.class.to_s.split('::').first)
          path = parent.instance_variable_get("@gem_path")
          Pathname.new path
        end

        def config
          @config ||= Rails::Engine::Configuration.new(get_plugin_path)
        end

        initializer "#{name.to_s.downcase}.static_assets" do |app|
          app.middleware.insert_before(::ActionDispatch::Static, ::ActionDispatch::Static, "#{root}/public")
        end
      end)
    end

    def parent_module
      Object.const_get(self.class.to_s.split('::').first)
    end

    def add_assets
      @javascripts = Assets::Javascripts.new(self, paths[:javascripts])
      @stylesheets = Assets::Stylesheets.new(self, paths[:stylesheets])
      @svgs        = Assets::Svgs.new(self, paths[:svgs])
    end

    def assets
      [@svgs, @stylesheets, @javascripts]
    end

    def build
      Command.from_root {
        FileUtils.mkdir_p(File.join(destination, asset_root))
      }
      threads = []
      assets.each do |asset|
        threads << Thread.new { asset.build }
      end

      threads
    end

    def watch
      assets.map(&:watch)
    end

    def config(options)
      options = {
        production_asset_root: "/assets/#{@name}",
        asset_root:    "/assets/#{@name}",
        destination:   "public/",
        root:          @gem.full_gem_path,
        version:       @gem.version.to_s,
        paths: {
          stylesheets: "app/assets/stylesheets/#{@name}",
          javascripts: "app/assets/javascripts/#{@name}",
          svgs:        "app/assets/svgs/#{@name}",
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

    def asset_root
      if Megatron.production? 
        plugin.production_asset_root
      else
        plugin.asset_root
      end
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

    def glob(asset_ext)

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
