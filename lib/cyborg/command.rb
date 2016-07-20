require "cyborg/command/help"
require "cyborg/command/npm"
require "cyborg/command/scaffold"

module Cyborg
  module Command
    extend self

    def run(options)
      @production = options[:production]

      case options[:command]
      when 'new', 'n'
        Scaffold.new(options[:name])
      when 'build', 'b'
        from_root { dispatch(:build, options) }
      when 'watch', 'w'
        from_root { dispatch(:watch, options) }
      when 'server', 's'
        from_root { dispatch(:server, options) }
      when 'gem:build'
        from_root { gem_build }
      when 'gem:install'
        from_root { gem_build }
      else
        puts "Command `#{options[:command]}` not recognized"
      end
    end

    def production?
      @production == true
    end

    def gem_build
      dispatch(:build, production: true)
      system "bundle exec rake build"
    end

    def gem_install
      dispatch(:build, production: true)
      system "bundle exec rake install"
    end

    def gem_release
      dispatch(:build, production: true)
      system "bundle exec rake release"
    end

    # Handles running threaded commands
    #
    def dispatch(command, *args)
      @threads = []
      send(command, *args)
      @threads.each { |thr| thr.join }
    end

    # Build assets
    def build(options={})
      puts Cyborg.production? ? 'Building for production…' : 'Building…'
      require File.join(Dir.pwd, Cyborg.rails_path('config/application'))
      @threads.concat Cyborg.plugin.build(options)
    end

    # Watch assets for changes and build
    def watch(options={})
      build(options)
      require 'listen'

      trap("SIGINT") { 
        puts "\nCyborg watcher stopped. Have a nice day!"
        exit! 
      }

      @threads.concat Cyborg.plugin.watch(options)
    end

    # Run rails server and watch assets
    def server(options={})
      @threads << Thread.new { system "#{Cyborg.rails_path('bin/rails')} server" }
      watch(options) if options[:watch]
    end

    def from_root(command=nil, &blk)
      unless dir = Cyborg.gem_path
        abort "Command must be run from the root of a Cyborg Plugin (adjacent to the gemspec)."
      end

      Dir.chdir(dir) do
        if command
          system command
        else
          blk.call
        end
      end
    end

  end
end


