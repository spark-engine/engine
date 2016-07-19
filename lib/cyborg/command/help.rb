module Cyborg
  module Help
    extend self

    def banner(command=nil)
      if command.nil?
        <<-HERE
Commands:
  #{commands.values.join("\n  ")}

For help with a specific command, run `cyborg help command`

Options:
        HERE
      elsif commands[command.to_sym]
        "\nUsage: #{commands[command.to_sym]}\n\nOptions:\n"
      end
    end

    def commands
      {
        new:   new,
        npm:   npm,
        build: build,
        watch: watch,
        help:  help
      }
    end

    def new
      "cyborg new project_name   # Create a new Cyborg based project"
    end

    def npm
      "cyborg npm [path]         # Add NPM dependencies (path: dir with package.json, defaults to '.')"
    end

    def build
      "cyborg build [options]    # Build assets"
    end

    def watch
      "cyborg watch [options]    # Build assets when files change"
    end

    def help
      "cyborg help [command]     # Show help for a specific command"
    end
  end
end
