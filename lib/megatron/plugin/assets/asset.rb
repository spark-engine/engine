module Megatron
  module Assets
    class Asset
      attr_reader :plugin, :path, :urls, :extension, :type, :relative, :versioned

      def initialize(plugin, path)
        @path = path
        @type = @@type
        @plugin = plugin
        @relative = path.sub(plugin.paths[type], '')
        @versioned = @relative.sub(/(\.\w+)$/, '-'+plugin.version+'\1')
      end

      def npm_cmd(cmd)

        # Split command to determine if the module is installed
        # example:
        #   `$(npm bin)/browserify` will return an empty string if
        #    browserify module isn't installed
        #
        installed = !`$(npm bin)/#{cmd.split(' ')[0]}`.empty?

        if installed
          system "$(npm bin)/#{cmd}"
          true
        else
          false
        end
      end

      def destination
        File.join(plugin.output, plugin.asset_root, versioned)
      end

      def url
        base = plugin.asset_root
        File.join(base, versioned)
      end

    end
  end
end
