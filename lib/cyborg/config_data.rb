module Cyborg
  module ConfigData
    extend self
    def read(*roots)
      @data ||= {}

      data_files(*roots).each do |path|
        name = File.basename(path, '.*')
        case File.extname(path)
        when '.json'
          @data[name] = JSON.parse(File.read(path))
        when '.yml'
          @data[name] = YAML.load_file(path)
        end
      end

      @data
    end

    def data_files(*roots)
      files = []
      [roots].flatten.each do |root|
        files.concat Dir[File.join(root, 'config/data/**/*.json')]
        files.concat Dir[File.join(root, 'config/data/**/*.yml')]
      end
      files.flatten.compact.uniq
    end
  end
end
