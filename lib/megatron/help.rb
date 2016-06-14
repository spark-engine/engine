module Megatron
  module Help
    extend self

    def banner(command=nil)
      if command.nil?
        <<-HERE
Commands:
  #{commands.values.join("\n  ")}

For help with a specific command, run `megatron help command`

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
        watch: watch,
        help: help
      }
    end

    def init
      "megatron init [path]        # Write default config file"
    end

    def npm
      "megatron npm [path]         # Add NPM dependencies (path: dir with package.json, defaults to '.')"
    end

    def build
      "megatron build [options]    # Build assets"
    end

    def watch
      "megatron watch [options]    # Build assets when files change"
    end

    def help
      "megatron help [command]     # Show help for a specific command"
    end
  end
end
