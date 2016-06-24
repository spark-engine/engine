module Megatron
  class Plugin
    attr_reader   :name, :module_name, :root, :version, :production_host,
                  :assets, :paths, :stylesheets, :javascripts, :svgs, :output

    def initialize(options)

      config(options)

      @root            ||= Gem.loaded_specs[name].full_gem_path
      @version         ||= Gem.loaded_specs[name].version
      @module_name     ||= name.split(/[-_]/).collect(&:capitalize).join

      expand_asset_paths

      @stylesheets        = Megatron::Assets.add_files(Assets::Sass)
      @stylesheets.concat   Megatron::Assets.add_files(Assets::Css)
      @javascripts        = Megatron::Assets.add_files(Assets::Javascipt)

      # Svgs rely on Esvg to process files so they get treated differently
      if Assets.find_files(Assets::Svg)
        @svgs = [Assets::Svg.new(plugin)]
      end

    end

    def build
      stylesheets.map(&:build)
      javascripts.map(&:build)
      svgs.map(&:build)
    end

    def config(options)
      name = options[:name].downcase!

      {
        production_asset_root: "/assets/#{name}/",
        asset_root:   "/assets/#{name}/",
        output:       "public/",
        root:          Gem.loaded_specs[name].full_gem_path,
        version:       Gem.loaded_specs[name].version,
        paths: {
          stylesheets: "app/assets/javascripts/#{name}/",
          javascripts: "app/assets/stylesheets/#{name}/",
          svgs:        "app/assets/svgs/#{name}/",
        }
      }.merge(options).each do |k,v|
        set_instance(k,v) 
      end
    end


    def expand_asset_paths
      @paths.each do |type, path|
        @paths[type] = File.join(root, path)
      end
    end

    def asset_root
      if Megatron.production? 
        plugin.production_asset_root
      else
        plugin.asset_root
      end
    end

    private

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
