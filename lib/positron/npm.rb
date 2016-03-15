module Positron
  module NPM
    extend self

    DEPENDENCIES = YAML.load %Q{
      autoprefixer: ^5.2.0
      babelify:     ^6.4.0
      browserify:   ^11.2.0
      minifyify:    ^7.3.2
      postcss-cli:  ^1.5.0
      svgo:         ^0.5.6
    }

    def config
      Positron.config
    end

    def setup
      require 'json'

      if File.exist?(package_path)
        install
      else
        if bool_ask("No package.json found at #{config[:cli_path]}\nWould you like to create one?")
          init_package_json
          install
        else
          return
        end
      end
    end

    def init_package_json
      # TODO: Create a package.json file with dev depenencies
    end

    def install
      Dir.chdir(config[:cli_path]) do
        system "npm install #{node_dependencies} -D"
      end
    end

    def bool_ask(question)
      puts "#{question} (Y\\n): "
      response = $stdin.gets.chomp
      response.nil? || !response.downcase.start_with?('n')
    end

    def package_path
      File.expand_path(File.join(config[:cli_path], 'package.json'))
    end

    def node_dependencies
      DEPENDENCIES.map do |k,v| 
        "#{k}@\"#{v}\""
      end.join(' ')
    end

    def node_dependencies_json
      JSON.generate(DEPENDENCIES)
    end

  end
end
