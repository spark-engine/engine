module Cyborg
  module Assets
    class AssetType
      attr_reader :plugin, :base

      def initialize(plugin, base)
        @base = base
        @plugin = plugin
      end

      def find_files
        if @files
          @files
        else
          files = Dir[File.join(base, "*.#{ext}")].reject do |f|
            # Filter out partials
            File.basename(f).start_with?('_')
          end

          @files = files if Cyborg.production?
          files
        end
      end

      def filter_files(names)

        # Filter names based on asset file locations
        find_files.select do |f|
          names.include? File.basename(f).sub(/(\..+)$/,'')
        end
      end

      def versioned(path)
        File.basename(path).sub(/(\.\w+)$/, '-'+plugin.version+'\1')
      end

      def local_path(file)
        destination(file).sub(plugin.root+'/','')
      end

      def build_success(file)
        log_success "Built: #{local_path(file)}"
      end

      def build_failure(file)
        msg = "\nFAILED TO BUILD"
        msg += ": #{local_path(file)}" if file
        log_error msg
      end

      def log_success( msg )
        STDOUT.puts msg.to_s.colorize(:green)
      end

      def log_error( msg )
        STDERR.puts msg.to_s.colorize(:red)
      end

      # Determine if an NPM module is installed by checking paths with `npm bin`
      # Returns path to binary if installed
    def find_node_module(cmd)
      require 'open3'
      (@modules ||= {})[cmd] ||= begin

        local = "$(npm bin)/#{cmd}"
        global = "$(npm -g bin)/#{cmd}"
        
        if Open3.capture3(local)[2].success?
          local
        elsif Open3.capture3(global)[2].success?
          global
        end

      end
    end

      def npm_command(cmd)
        cmd = cmd.split(' ')
        if path = find_node_module(cmd.shift)
          system "#{path} #{cmd.join(' ')}"
        end
      end

      def destination(path)
        plugin.asset_path(versioned(path))
      end

      def url(path)
        plugin.asset_url(versioned(path))
      end

      def urls(names=nil)
        # If names are passed, look at the basename minus
        # the extension as build files may have
        # different extensions than sources
        names = [names].flatten.compact.map do |n|
          File.basename(n).sub(/(\..+)$/,'')
        end

        # Return all asset urls if none were specifically chosen
        if names.empty?
          find_files.map{ |file| url(file) }

        # Filter files based on name
        else
          filter_files(names).map{ |file| url(file) }
        end
      end

      def watch

        @throttle = 4
        @last_build = 0
        
        puts "Watching for changes to #{base.sub(plugin.root+'/', '')}...".colorize(:light_yellow)

        Thread.new {
          listener = Listen.to(base) do |modified, added, removed|
            change(modified, added, removed)
          end

          listener.start # not blocking
          sleep
        }
      end

      def change(modified, added, removed)
        return if (Time.now.to_i - @last_build) < @throttle

        puts "Added: #{file_event(added)}".colorize(:light_green)        unless added.empty?
        puts "Removed: #{file_event(removed)}".colorize(:light_red)      unless removed.empty?
        puts "Modified: #{file_event(modified)}".colorize(:light_yellow) unless modified.empty?

        build
        @last_build = Time.now.to_i
      end

      def file_event(files)
        list = files.flat_map { |f| f.sub(base+'/', '') }.join("  \n")
        list = "  \n#{files}" if 1 < files.size

        list
      end

      def compress(file)
        return unless Cyborg.production?

        mtime = File.mtime(file)
        gz_file = "#{file}.gz"
        return if File.exist?(gz_file) && File.mtime(gz_file) >= mtime

        File.open(gz_file, "wb") do |dest|
          gz = Zlib::GzipWriter.new(dest, Zlib::BEST_COMPRESSION)
          gz.mtime = mtime.to_i
          IO.copy_stream(open(file), gz)
          gz.close
        end

        File.utime(mtime, mtime, gz_file)
      end
    end
  end
end
