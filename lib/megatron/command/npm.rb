module Megatron
  module NPM
    extend self

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

    def config
      Megatron.config
    end

    def setup
      require 'json'

      paths = [config[:npm_dir], config[:cli_path]].compact
      config[:npm_dir] = paths.select{ |p| File.directory?(File.expand_path(p))}.first

      if File.exist?(package_path)
        install
      else
        if bool_ask("No package.json found at #{config[:npm_dir]}\nWould you like to create one?")
          write_package_json(DEPENDENCIES)
          install
        else
          return
        end
      end
    end

    def install
      Dir.chdir(config[:npm_dir]) do
        update_package_json
        system "npm install"
      end
    end

    def bool_ask(question)
      print "#{question} (Y\\n): "
      response = $stdin.gets.chomp
      response.nil? || !response.downcase.start_with?('n')
    end

    def package_path
      File.expand_path(File.join(config[:npm_dir], 'package.json'))
    end

    def node_dependencies
      DEPENDENCIES['devDependencies'].map do |k,v| 
        "#{k}@\"#{v}\""
      end.join(' ')
    end

    def write_package_json(contents)
      FileUtils.mkdir_p(config[:npm_dir])
      File.open(File.join(config[:npm_dir], 'package.json'), 'w') do |io|
        io.write(JSON.pretty_generate(contents))
      end
    end

    def read_package_json
      JSON.parse(File.read(File.join(config[:npm_dir], 'package.json')))
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

    def update_dependency(package, dependency)

    end

  end
end
