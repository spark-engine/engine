require "yaml"

require "megatron/command/watch"
require "megatron/command/help"
require "megatron/command/npm"
require "megatron/command/compress"

module Megatron
  module Command
    extend self

    def run(options)

      require 'gondor'

      case options[:command]
      #when 'init' 
        #Config.write(options)
      when 'npm' 
        NPM.setup
      when 'build'
        puts 'building'

        threads = []
        Megatron.plugins.each do |plugin|

          FileUtils.mkdir_p(File.join(plugin.paths[:output], plugin.asset_root))

          plugin.assets.each do |asset|
            puts asset.destination
            threads << Thread.new { asset.build }
          end
        end

        threads.each { |thr| thr.join }
      when 'watch'
        Watch.run
      else
        puts "Command `#{options[:command]}` not recognized"
      end
    end

  end
end
