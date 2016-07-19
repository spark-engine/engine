module Cyborg
  module Help
    extend self

    def banner(command=nil)
      if command.nil?
        <<-HERE
Commands:
  #{command_list.map{|c| commands(c.to_sym) }.join("\n  ")}

For help with a specific command, run `cyborg help command`

Options:
        HERE
      elsif commands(command.to_sym)
        "\nUsage:\n  cyborg #{commands(command.to_sym)}\n\nOptions:\n"
      end
    end

    def command_list
      %w(new build watch server help)
    end

    def commands(command)
      case command
      when :new, :n; new
      when :build, :b; build
      when :watch, :w; watch
      when :server, :s; server
      when :help, :h; help
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

    def help
      "help [command]       # Show help for a specific command"
    end
  end
end
