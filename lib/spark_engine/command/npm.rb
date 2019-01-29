module SparkEngine
  module NPM
    extend self

    require "yaml"

    DEPENDENCIES = YAML.load %Q{
    private: true
    devDependencies:
      browserify: ^16.2.1
      browserify-incremental: ^3.1.1
      uglify-js: ^3.4.9
      svgo: ^1.0.5
    }

    def setup
      puts "\nAdding npm dependencies…".bold

      if File.exist?(package_path)
        update_package_json
      else
        write_package_json(DEPENDENCIES)
      end
    end

    def package_path
      File.join(Dir.pwd, 'package.json')
    end

    def write_package_json(contents)
      File.open(package_path, 'w') do |io|
        io.write(JSON.pretty_generate(contents))
      end

      puts "create".rjust(12).colorize(:green).bold + "  #{package_path}"
    end

    def read_package_json
      JSON.parse File.read(package_path)
    end

    def update_package_json
      package = read_package_json
      package['dependencies']    ||= {}
      package['devDependencies'] ||= {}

      deps = DEPENDENCIES['devDependencies']

      deps.keys.each do |dep|
        d = deps[dep]

        if package['devDependencies'][dep].nil? && package['dependencies'][dep].nil?
          package['devDependencies'][dep] = d
        end
      end

      package.delete('dependencies') if package['dependencies'].empty?
      
      write_package_json(package)
    end

  end
end
