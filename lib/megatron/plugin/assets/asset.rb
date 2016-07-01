module Megatron
  module Assets
    class AssetType
      attr_reader :plugin, :base

      def initialize(plugin, base)
        @base = base
        @plugin = plugin
      end

      def find_files
        files = Dir[File.join(base, "*.#{ext}")]

        # Filter out partials
        files.reject { |f| File.basename(f).start_with?('_') }
      end

      def versioned(path)
        File.basename(path).sub(/(\.\w+)$/, '-'+plugin.version+'\1')
      end

      def build_msg(file)
        "Built: #{destination(file).sub(plugin.root+'/','')}"
      end

      # Determine if an NPM module is installed by checking paths with `npm ls`
      # Returns path to binary if installed
      def find_node_module(cmd)
        require 'open3'

        response = Open3.capture3("npm ls #{cmd}")

        # Look in local `./node_modules` path.
        # Be sure stderr is empty (the second argument returned by capture3)
        if response[1].empty?
          "$(npm bin)/#{cmd}"

        # Check global module path
        elsif Open3.capture3("npm ls -g #{cmd}")[1].empty?
          cmd
        end
      end

      def npm_command(cmd)
        cmd = cmd.split(' ')
        path = find_node_module(cmd.shift)
        if path
          system "#{path} #{cmd.join(' ')}"
        end
      end

      def destination(path)
        File.join(plugin.destination, plugin.asset_root, versioned(path))
      end

      def url(path)
        File.join(plugin.asset_root, versioned(path))
      end

      def urls
        find_files.map{ |file| url(file) }
      end

      def watch
        puts "Watching for changes to #{base.sub(plugin.root+'/', '')}..."

        Thread.new {
          listener = Listen.to(base) do |modified, added, removed|
            change(modified, added, removed)
          end

          listener.start # not blocking
          sleep
        }
      end

      def change(modified, added, removed)
        puts "Added: #{file_event(added)}"       unless added.empty?
        puts "Removed: #{file_event(removed)}"   unless removed.empty?
        puts "Modified: #{file_event(modified)}" unless modified.empty?

        build
      end

      def file_event(files)
        list = files.map { |f| f.sub(base+'/', '') }.join("  \n")
        list = "  \n#{files}" if 1 < files.size

        list 
      end

    end
  end
end
