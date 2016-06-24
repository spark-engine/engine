module Megatron
  module Assets
    class Javascipt < Megatron::Asset
      @@type = :javascripts
      @@extension = 'js'

      def build
        dest = destination.sub(/\.js$/,'')

        cmd = " #{path} -t babelify --standalone #{plugin.module_name} -o #{dest}.js "
        cmd += "-d -p [ minifyify --map #{File.basename(dest)}.map.json --output #{dest}.map.json ]"

        if npm_cmd('browserify', cmd)
          puts "Built: #{versioned}"
        else
          puts "BUILD FAILED: Browserfy NPM module not found."
          puts "Please add browserify to your package.json and run `npm install`"
          exit!
        end
      end
    end
  end
end
