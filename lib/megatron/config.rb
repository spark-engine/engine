require 'yaml'
require 'pp'

module Megatron
  module Config
    extend self

    DEFAULTS = %Q{
      # Name for your module's global
      name: Megatron

      javascripts_dir: app/assets/javascripts/megatron
      stylesheets_dir: app/assets/stylesheets/megatron
      images_dir: app/assets/images/megatron
      svg_dir: app/assets/svg/megatron

      output_dir: public/assets/megatron

      npm_dir: ./
    }

    def defaults
      symbolize YAML.load(DEFAULTS)
    end

    def load(cli_options={})
      file_config = defaults.merge read(config_file(cli_options))

      # Merge with oder: Defaults < File Config < CLI options
      #
      config = defaults.merge(file_config.merge(cli_options))

      root = Megatron.root(config[:name])

      config[:stylesheets_dir] = File.join(root, config[:stylesheets_dir])
      config[:javascripts_dir] = File.join(root, config[:javascripts_dir])
      config[:svg_dir]    = File.join(root, config[:svg_dir])
      config[:output_dir] = File.join(root, config[:output_dir])
      config[:npm_dir]    = File.join(root, config[:npm_dir])

      config[:assets].select! do |type|
        dir = config["#{type}_dir".to_sym]
        File.directory?(File.expand_path(dir))
      end

      config
    end
    
    def config_file(options)
      paths = [options[:config_file], 'config/megatron.yml', 'megatron.yml'].compact
      paths.select{ |p| File.exist?(File.expand_path(p))}.first
    end

    def write(options)
      file = config_file(options)

      if (file && !options[:force])
        puts options
        puts "File exists: #{file.sub(File.expand_path('.')+'/', '')}. Use --force to overwrite"
      else
        dir = File.directory?('./config/') ? './config/' : './'
        file ||= File.expand_path(File.join(dir, 'megatron.yml'))

        File.open(file, 'w') do |io|
          io.write DEFAULTS.lstrip.gsub(/^ +/,'')
        end

        puts "Default config written to #{file.sub(File.expand_path('.')+'/', '')}"
      end
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
