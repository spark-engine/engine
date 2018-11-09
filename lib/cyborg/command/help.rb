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
      %w(new help)
    end

    def commands(command)
      case command
      when 'new', 'n'; new
      when 'help', 'h'; help
      end
    end

    def new
      "new [path/to/]<project_name> [options]  # Create a new Cyborg project"
    end

    def help
      "help [command]       # Show help for a specific command"
    end
  end
end
