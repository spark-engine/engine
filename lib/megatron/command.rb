require "megatron/command/help"
require "megatron/command/npm"

module Megatron
  module Command
    extend self

    def run(options)

      case options[:command]
      when 'new'
        #Config.write(options)
      when 'npm' 
        from_root { NPM.setup }
      when 'build'
        frok_rails { "rake megatron:build" }
      when 'watch'
        frok_rails { "rake megatron:watch" }
      when 'server'
        frok_rails { "rake megatron:server" }
      else
        puts "Command `#{options[:command]}` not recognized"
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
