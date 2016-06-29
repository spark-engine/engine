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

      # Determine if an NPM module is installed
      # `$(npm bin)/browserify` will return an empty string if
      #  browserify module isn't installed
      def npm_module_installed(cmd)
        !`$(npm bin)/#{cmd}`.empty?
      end

      def npm_sh(cmd)
        system "$(npm bin)/#{cmd}"
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
