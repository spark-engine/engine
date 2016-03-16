module Positron
  module Config
    extend self

    DEFAULTS = {
      app_name:       'application',
      js_dir:         './app/assets/positron/javascripts/',
      sass_dir:       './app/assets/positron/stylesheets/',
      svg_dir:        './app/assets/positron/svgs/',
      output_dir:     './public/assets/positron/',
      npm_dir:        './node_modules',
      js_module_name: 'Positron'
    }

    def load(cli_options={})
      file_config = read(config_file(cli_options))

      # Merge with oder: Defaults < File Config < CLI options
      #
      config = DEFAULTS.merge file_config.merge(cli_options)

      config[:sass_dir]   = File.expand_path(config[:sass_dir])
      config[:js_dir]     = File.expand_path(config[:js_dir])
      config[:svg_dir]    = File.expand_path(config[:svg_dir])
      config[:output_dir] = File.expand_path(config[:output_dir])
      config[:npm_dir]    = File.expand_path(config[:npm_dir])

      FileUtils.mkdir_p(config[:output_dir])

      config[:assets].select! do |type|
        dir = config["#{type}_dir".to_sym]
        File.directory?(File.expand_path(dir))
      end

      config
    end
    
    def config_file(options)
      paths = [options[:config_file], 'config/positron.yml', 'positron.yml'].compact
      paths.select{ |p| File.exist?(File.expand_path(p))}.first
    end

    def read(file)
      if file
        symbolize(YAML.load(File.read(file)))
      else
        {}
      end
    end

    def symbolize(obj)
      if obj.is_a? Hash
        return obj.inject({}) do |memo, (k, v)|
          memo.tap { |m| m[k.to_sym] = symbolize(v) }
        end
      elsif obj.is_a? Array
        return obj.map { |memo| symbolize(memo) }
      end
      obj
    end
  end
end
