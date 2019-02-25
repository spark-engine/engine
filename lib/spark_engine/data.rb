module SparkEngine
  module Data
    extend self

    def read
      data_files(SparkEngine.plugin.root, Rails.root).each_with_object({}) do |path, data|
        name = File.basename(path, '.*')
        data[name] ||= {}

        case File.extname(path)
        when '.json'
          data[name].merge!(JSON.parse(File.read(path)))
        when '.yml'
          data[name].merge!(YAML.load_file(path))
        end

        data
      end
    end

    def data_files(*roots)
      files = []
      [roots].flatten.each do |root|
        files.concat Dir[File.join(root, 'config', SparkEngine.plugin.name, '**/*.json')]
        files.concat Dir[File.join(root, 'config', SparkEngine.plugin.name, '**/*.yml')]
      end
      files.flatten.compact.uniq
    end
  end
end
