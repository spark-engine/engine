module Positron
  module Watch
    extend self

    def config
      Positron.config
    end

    def run
      trap("SIGINT") { 
        puts "\nWatcher stopped. Have a nice day!"
        exit! 
      }

      Build.run

      threads = []

      config[:assets].each do |asset|
        threads << listen(asset.to_sym)
      end

      puts "Watching for changes to #{config[:assets].join(', ')}..."

      threads.compact.each { |thr| thr.join }
    end

    def listen(type)
      require 'listen'

      Thread.new {
        listener = Listen.to(dir, only: /#{type}$/) do |modified, added, removed|
          Build.public_send(type)
        end

        listener.start # not blocking
        sleep
      }
    end
  end
end
