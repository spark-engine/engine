module Cyborg
  module NPM
    extend self

    require "yaml"

    DEPENDENCIES = YAML.load %Q{
    private: true
    devDependencies:
      autoprefixer: ^5.2.0
      babelify:     ^6.4.0
      browserify:   ^11.2.0
      minifyify:    ^7.3.2
      postcss-cli:  ^1.5.0
      svgo:         ^0.5.6
    }

    def setup
      puts "\nInstalling npm dependencies…".bold

      if File.exist?(package_path)
        update_package_json
        install
      else
        write_package_json(DEPENDENCIES)
        install
      end
    end

    def install
      system "npm install"
    end

    def package_path
      File.join(Dir.pwd, 'package.json')
    end

    def node_dependencies
      DEPENDENCIES['devDependencies'].map do |k,v| 
        "#{k}@\"#{v}\""
      end.join(' ')
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
