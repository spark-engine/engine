require "yaml"

#require "megatron/command/watch"
require "megatron/command/help"
require "megatron/command/npm"
#require "megatron/command/compress"

module Megatron
  module Command
    extend self

    def run(options)

      case options[:command]
      when 'init' 
        #Config.write(options)
      when 'npm' 
        from_root { NPM.setup }
      when 'build'
        rake(:build)
      when 'watch'
        rake(:watch)
      when 'server'
        rake(:server)
      else
        puts "Command `#{options[:command]}` not recognized"
      end
    end

    def rake(command)
      from_rails do
        system "rake megatron:#{command}"
      end
    end

    def root(command)
      from_root do
        system "rake megatron:#{command}"
      end
    end

    def from_rails(&blk)
      unless dir = Megatron.rails_path
        puts "Command must be run from the root of a Megatron Plugin project, or in its Rails 'site' directory."
        exit!
      end

      Dir.chdir(dir) do
        blk.call
      end
    end

    def from_root(&blk)
      unless dir = Megatron.gem_path
        puts "Command must be run from the root of a Megatron Plugin (adjacent to the gemspec)."
        exit!
      end

      Dir.chdir(dir) do
        blk.call
      end
    end

  end
end
