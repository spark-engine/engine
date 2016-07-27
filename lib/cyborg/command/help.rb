module Cyborg
  module Help
    extend self

    def banner(command=nil)
      if command.nil?
        <<-HERE
Commands:
  #{command_list.map{|c| commands(c) }.join("\n  ")}

For help with a specific command, run `cyborg help command`

Options:
        HERE
      elsif commands(command)
        "\nUsage:\n  cyborg #{commands(command)}\n\nOptions:\n"
      end
    end

    def command_list
      %w(new build watch server help gem:build gem:install gem:release)
    end

    def commands(command)
      case command
      when 'new', 'n'; new
      when 'build', 'b'; build
      when 'watch', 'w'; watch
      when 'server', 's'; server
      when 'clean', 'c'; clean
      when 'help', 'h'; help
      when 'gem:build'; gem_build
      when 'gem:install'; gem_install
      when 'gem:release'; gem_release
      end
    end

    def new
      "new <project_name>   # Create a new Cyborg project"
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
  end
end
