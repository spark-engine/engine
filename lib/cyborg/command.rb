require "cyborg/command/help"
require "cyborg/command/npm"
require "cyborg/command/scaffold"

module Cyborg
  module Command
    extend self

    def run(options)

      case options[:command]
      when 'new'
        Scaffold.new(options[:name])
      when 'npm' 
        from_root { NPM.setup }
      when 'build'
        from_rails "bundle exec rake cyborg:build"
      when 'watch'
        from_rails "rake cyborg:watch"
      when 'server'
        from_rails "rake cyborg:server"
      when 'rails'
        from_rails "rails s"
      else
        puts "Command `#{options[:command]}` not recognized"
      end
    end

    def from_rails(command=nil, &blk)
      unless dir = Cyborg.rails_path
        abort "Command must be run from the root of a Cyborg Plugin project, or in its Rails 'site' directory."
      end

      Dir.chdir(dir) do
        if command
          system command
        else
          blk.call
        end
      end
    end

    def from_root(command=nil, &blk)
      unless dir = Cyborg.gem_path
        abort "Command must be run from the root of a Cyborg Plugin (adjacent to the gemspec)."
      end

      Dir.chdir(dir) do
        if command
          system command
        else
          blk.call
        end
      end
    end

  end
end


