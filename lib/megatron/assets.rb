module Megatron
  module Assets
    extend self

    autoload :Asset,               'megatron/plugin/assets/asset'
    autoload :Sass,                'megatron/plugin/assets/sass'
    autoload :Css,                 'megatron/plugin/assets/css'
    autoload :Javascript,          'megatron/plugin/assets/javascript'
    autoload :Svg,                 'megatron/plugin/assets/svg'

    def glob(type, extension)
      files = []
      [extension].flatten.each do |ext|
        files.push Dir[File.join(@paths[type], "*.#{ext}")]
      end

      # Filter out partials
      files.reject { |f| File.basename(f).start_with?('_') }
    end

    # Find files by class type and extension
    def find_files(klass)
      glob(klass.type, klass.extension)
    end
    
    # Find files based on class type and
    # return an array of Classes for each file
    def add_files(klass)
      find_files(klass).map do |f| 
        klass.new(plugin, f)
      end
    end

  end
end
