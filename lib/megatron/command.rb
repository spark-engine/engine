require "yaml"

require "megatron/command/build"
require "megatron/command/watch"
require "megatron/command/help"
require "megatron/command/npm"
require "megatron/command/compress"

module Megatron
  module Command
    extend self

    def run(options)
      Megatron.config(options)

      case Megatron.config[:command]
      when 'init' 
        Config.write(options)
      when 'npm' 
        NPM.setup
      when 'build'
        Build.run
      when 'watch'
        Watch.run
      else
        puts "Command `#{Megatron.config[:command]}` not recognized"
      end
    end

  end
end
