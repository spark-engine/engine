module Positron
  module Help
    extend self

    def banner(command=nil)
      if command.nil? || command == 'help'
        <<-HERE
Commands:
  #{commands.values.join("\n  ")}

For help with a specific command, run `positron help command`

Options:
        HERE
      elsif commands[command.to_sym]
        "\nUsage: #{commands[command.to_sym]}\n\nOptions:\n"
      end
    end

    def commands
      {
        init:  init,
        npm:   npm,
        build: build,
        watch: watch
      }
    end

    def init
      "positron init [path]  # Write default config file"
    end

    def npm
      "positron npm [path]   # Add NPM devDependencies to your package.json"
    end

    def build
      "positron build [options]"
    end

    def watch
      "positron watch [options]"
    end
  end
end
