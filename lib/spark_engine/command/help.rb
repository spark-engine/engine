module SparkEngine
  module Help
    extend self

    def banner(command=nil)
      if command.nil?
        <<-HERE
General Commands (run from anywhere):
  #{spark_commands.map{|c| commands(c) }.join("\n  ")}

Engine Commands (run these from your project's directory)
  #{engine_commands.map{|c| commands(c) }.join("\n  ")}

For help with a specific command, run `spark help command`

Options:
        HERE
      elsif commands(command)
        "\nUsage:\n  spark #{commands(command)}\n\nOptions:\n"
      end
    end

    def engine_commands
      list = %w(help build watch server help gem:build gem:install gem:release)
      begin
        gem 'bump'
        list.concat %w(gem:bump:patch gem:bump:minor gem:bump:major)
      rescue Gem::LoadError
      end

      list
    end

    def spark_commands
      %w(new help)
    end

    def commands(command)
      case command
      when 'new', 'n'; new
      when 'help', 'h'; help
      when 'build', 'b'; build
      when 'watch', 'w'; watch
      when 'server', 's'; server
      when 'clean', 'c'; clean
      when 'help', 'h'; help
      when 'gem:build'; gem_build
      when 'gem:install'; gem_install
      when 'gem:release'; gem_release
      when 'gem:bump:patch'; gem_bump_patch
      when 'gem:bump:minor'; gem_bump_minor
      when 'gem:bump:major'; gem_bump_major
      end
    end

    def new
      "new name [options]   # Create a new Spark framework engine"
    end

    def help
      "help [command]       # Show help for a specific command"
    end

    def build
      "build [options]      # Build assets"
    end

    def watch
      "watch [options]      # Build assets when files change"
    end

    def server
      "server [options]     # Serve documentation site"
    end

    def clean
      "clean                # Remove cache files"
    end

    def help
      "help [command]       # Show help for a specific command"
    end

    def gem_build
      "gem:build            # Build assets for production and build gem"
    end

    def gem_install
      "gem:install          # Build assets for production, build, and install gem"
    end

    def gem_release
      "gem:release          # Build assets for production, build, and release gem to rubygems.org"
    end

    def gem_bump_patch
      "gem:bump:patch       # Upgrade v0.0.0 -> v0.0.1 and build assets"
    end

    def gem_bump_minor
      "gem:bump:minor       # Upgrade v0.0.0 -> v0.1.0 and build assets"
    end

    def gem_bump_major
      "gem:bump:major       # Upgrade v0.0.0 -> v1.0.0 and build assets"
    end
  end
end
