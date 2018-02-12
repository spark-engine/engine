require "cyborg/command/help"
require "cyborg/command/npm"
require "cyborg/command/scaffold"

module Cyborg
  module Command
    extend self

    def run(options)
      @production = options[:production]

      if options[:help]
        version
        puts options[:help]
        return
      end

      case options[:command]
      when 'new', 'n'
        Scaffold.new(options)
      when 'build', 'b'
        from_root { dispatch(:build, options) }
      when 'watch', 'w'
        from_root { dispatch(:watch, options) }
      when 'server', 's'
        from_root { dispatch(:server, options) }
      when 'clean', 'c'
        from_root { clean }
      when 'version'
        version
      when 'gem:build'
        from_root { gem_build }
      when 'gem:install'
        from_root { gem_install }
      when 'gem:release'
        from_root { gem_release }
      when 'gem:tag'
        from_root { gem_tag }
      else
        puts "Command `#{options[:command]}` not recognized"
      end
    end

    def version
      puts "Cyborg version #{Cyborg::VERSION}\n\n"
    end

    def production?
      @production == true
    end

    def gem_build
      @production = true
      FileUtils.rm_rf('public')
      dispatch(:build)
      system "bundle exec rake build"
    end

    def gem_install
      @production = true
      FileUtils.rm_rf('public')
      dispatch(:build)
      system "bundle exec rake install"
    end

    def gem_release
      @production = true
      FileUtils.rm_rf('public')
      dispatch(:build)

      if key = ENV['RUBYGEMS_API_KEY']
        gem = "#{Cyborg.plugin.gem_name}-#{Cyborg.plugin.version}.gem"
        system "bundle exec rake build"
        system "curl --data-binary @./pkg/#{gem} -H 'Authorization:#{key}' https://rubygems.org/api/v1/gems"
      else
        system 'bundle exec rake release'
      end
    end

    def gem_tag
      require './lib/tungsten/version.rb'
      system "git tag v#{Tungsten::VERSION}"
    end

    def require_rails
      require File.join(Dir.pwd, Cyborg.rails_path('config/application'))
    end

    def clean
      FileUtils.rm_rf(Cyborg.rails_path('tmp/cache/'))
      FileUtils.rm_rf('.sass-cache')
      FileUtils.rm_rf(Cyborg.rails_path('.sass-cache'))
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
      require_rails
      clean if Cyborg.production?
      Cyborg.plugin.build(options)
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
      options[:port] ||= 3000
      @threads << Thread.new { system "#{Cyborg.rails_path('bin/rails')} server -p #{options[:port]}" }
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


