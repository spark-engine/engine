module Positron
  module Watch
    extend self

    def config
      Positron.config
    end

    def run
      require 'listen'

      trap("SIGINT") { 
        puts "\nPositron watcher stopped. Have a nice day!"
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
      dir = config["#{type}_dir".to_sym]
      method = Build.method(type)

      Thread.new {
        listener = Listen.to(dir) do |modified, added, removed|
          trigger(type, modified, added, removed)
        end

        listener.start # not blocking
        sleep
      }
    end

    def trigger(type, modified, added, removed)
      puts "Added: #{file_event(type, added)}"       unless added.empty?
      puts "Removed: #{file_event(type, removed)}"   unless removed.empty?
      puts "Modified: #{file_event(type, modified)}" unless modified.empty?

      Build.public_send(type)
    end

    def file_event(type, files)
      dir = config["#{type}_dir".to_sym]

      list = files.map { |f| f.sub(dir+'/', '') }.join("  \n")
      list = "  \n#{files}" if 1 < files.size

      list 
    end
  end
end
