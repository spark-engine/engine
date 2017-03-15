module Cyborg
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

        require 'cyborg/middleware'

        initializer "#{name}.static_assets" do |app|
          if !Cyborg.rails5? || app.config.public_file_server.enabled
            app.middleware.insert_after ::ActionDispatch::Static, Cyborg::StaticAssets, "#{root}/public", engine_name: Cyborg.plugin.name
            app.middleware.insert_before ::ActionDispatch::Static, Rack::Deflater
          end
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

      path = if Cyborg.production? && !ENV[name.upcase + '_FORCE_LOCAL_ASSETS']
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
