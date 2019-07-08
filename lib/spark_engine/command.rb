module SparkEngine
  module Command
    extend self

    def run(options)
      @production = options[:production]

      if options[:help]
        version
        puts options[:help]
        return
      end

      if options[:clean] || SparkEngine.production?
        from_root { clean }
      end

      case options[:command]
      when 'new', 'n'
        require "spark_engine/scaffold"
        Scaffold.new(options)
      when 'generate', 'g'
        from_root { 
          require "spark_engine/scaffold"
          require_rails
          Scaffold.new(options) 
        }
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
      when 'gem:bump:patch'
        from_root { gem_bump('patch') }
      when 'gem:bump:minor'
        from_root { gem_bump('minor') }
      when 'gem:bump:major'
        from_root { gem_bump('major') }
      else
        puts "Command `#{options[:command]}` not recognized"
      end
    end

    def version
      spec = SparkEngine.plugin_spec
      puts "spark_engine v #{SparkEngine::VERSION}"
      puts " - #{spec.name} v #{spec.version}\n" if spec
      puts ""
    end

    def production?
      @production == true
    end

    def gem_build
      @production = true
      FileUtils.rm_rf('public')
      dispatch(:build)
      system "bundle exec rake build"
      system "git add Gemfile.lock lib"
    end

    def gem_install
      @production = true
      FileUtils.rm_rf('public')
      dispatch(:build)
      system "bundle exec rake install"
    end

    def gem_release
      @production = true
      gem_build
      spec = SparkEngine.plugin_spec
      gem_file = "./pkg/#{spec.name}-#{spec.version}.gem"

      if File.exists?(gem_file)
        system "git commit -m v#{spec.version}"
        gem_tag
        system "git push origin $(git rev-parse --abbrev-ref HEAD) --tag"

        if key = ENV['RUBYGEMS_API_KEY']
          gem = "#{spec.name}-#{spec.version}.gem"
          system "bundle exec rake build"
          system "curl --data-binary @./pkg/#{gem} -H 'Authorization:#{key}' https://rubygems.org/api/v1/gems"
        else
          system "gem push #{gem_file}"
          system "rm ./public/*.gz"
        end
      end
    end

    def gem_bump(v)
      system "bump #{v} --no-commit"
    end

    def gem_tag
      system "git tag v#{SparkEngine.plugin_spec.version}"
    end

    def require_rails
      require File.join(Dir.pwd, SparkEngine.rails_path('config/application'))
    end

    def clean
      FileUtils.rm_rf('public')
      FileUtils.rm_rf(SparkEngine.rails_path('tmp/cache/'))
      FileUtils.rm_rf('.sass-cache')
      FileUtils.rm_rf(SparkEngine.rails_path('.sass-cache'))
    end

    # Handles running threaded commands
    #
    def dispatch(command, *args)
      @threads = []
      send command, *args
      @threads.each { |thr| thr.join }
    end

    # Build assets
    def build(options={})
      puts SparkEngine.production? ? 'Building for production…' : 'Building…'
      require_rails
      SparkEngine.plugin.build(options)
    end

    # Watch assets for changes and build
    def watch(options={})
      build(options)
      require 'listen'

      trap("SIGINT") {
        puts "\nspark_engine watcher stopped. Have a nice day!"
        exit!
      }

      @threads.concat SparkEngine.load_plugin.watch(options)
    end

    # Run rails server and watch assets
    def server(options={})
      options[:port] ||= 3000
      @threads << Thread.new { system "#{SparkEngine.rails_path('bin/rails')} server -p #{options[:port]}" }
      watch(options) if options[:watch]
    end

    def from_root(command=nil, &blk)
      unless SparkEngine.gem_path
        abort "Command must be run from the root of an engine (adjacent to the gemspec)."
      end

      Dir.chdir(SparkEngine.gem_path) do
        if command
          system command
        else
          blk.call
        end
      end
    end

  end
end


