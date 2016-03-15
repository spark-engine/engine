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
      system "npm install #{node_dependencies} -D"
    end

    def node_dependencies
      NODE_DEPENDENCIES.map do |k,v| 
        "#{k}@\"#{v}\""
      end.join(' ')
    end

    def node_dependencies_json
      require 'json'
      JSON.generate(NODE_DEPENDENCIES)
    end

  end
end
