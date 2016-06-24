require "yaml"

require "megatron/command/watch"
require "megatron/command/help"
require "megatron/command/npm"
require "megatron/command/compress"

module Megatron
  module Command
    extend self

    def run(options)
      config = Megatron.config(options)

      case config[:command]
      when 'init' 
        Config.write(options)
      when 'npm' 
        NPM.setup
      when 'build'
        Build.run
      when 'watch'
        Watch.run
      else
        puts "Command `#{config[:command]}` not recognized"
      end
    end

  end
end
