module Cyborg
  class Plugin
    attr_reader   :name, :gem, :engine,
                  :stylesheets, :javascripts, :svgs, :destination

    def initialize(options)
      @name            = options.delete(:engine).downcase
      @gem             = Gem.loaded_specs[options.delete(:gem)]
      @maps            = false
      config(options)
      expand_asset_paths

      # Store the gem path for access later when overriding root
      parent_module.instance_variable_set(:@gem_path, root)
      parent_module.instance_variable_set(:@cyborg_plugin_name, name)
      add_assets
    end

    def engine_name
      @engine.name.sub(/::Engine/,'')
    end

    def create_engine
      # Create a new Rails::Engine
      @engine = parent_module.const_set('Engine', Class.new(Rails::Engine) do

        def cyborg_plugin_path
          parent = Object.const_get(self.class.name.sub(/::Engine/,''))
          Pathname.new parent.instance_variable_get("@gem_path")
        end

        def config
          @config ||= Rails::Engine::Configuration.new(cyborg_plugin_path)
        end

        engine_name Cyborg.plugin.name

        initializer "#{name}.static_assets" do |app|
          app.middleware.insert_before(::ActionDispatch::Static, ::ActionDispatch::Static, "#{root}/public")
        end
      end)
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

    def maps?
      @maps == true
    end

    def svgs?
      @svgs.icons.nil?
    end

    def build(options={})
      @maps = options[:maps] || Cyborg.production?
      # TODO: be sure gem builds use a clean asset_path
      #FileUtils.rm_rf(root) if Cyborg.production?
      FileUtils.mkdir_p(asset_path)
      threads = []
      assets(options).each do |asset|
        threads << Thread.new { asset.build }
      end

      threads
    end

    def watch(options)
      @maps = options[:maps] || Cyborg.production?
      assets(options).map(&:watch)
    end

    def clean
      FileUtils.rm_rf(Cyborg.rails_path('tmp/cache/'))
      FileUtils.rm_rf('.sass-cache')
      FileUtils.rm_rf(Cyborg.rails_path('.sass-cache'))
    end

    def config(options)
      options = {
        production_asset_root: "/assets/#{name}",
        asset_root:    "/assets/#{name}",
        destination:   "public/",
        root:          @gem.full_gem_path,
        version:       @gem.version.to_s,
        paths: {
          stylesheets: "app/assets/stylesheets/#{name}",
          javascripts: "app/assets/javascripts/#{name}",
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
      dest = File.join(destination, asset_root)
      dest = File.join(dest, file) if file
      dest
    end

    def asset_url(file=nil)
      path = if Cyborg.production? 
        production_asset_root
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
