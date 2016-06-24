module Megatron
  module Assets
    class Sass < Megatron::Asset
      @@type = :stylesheets
      @@extension = %w(scss sass)

      def build
        style = 'nested'
        sourcemap = 'true'

        if Megatron.production?
          style = "compressed"
          sourcemap = 'false'
        end

        dest = destination

        system "sass #{file}:#{dest} --style #{style} --sourcemap=#{sourcemap}"
        npm_cmd("postcss --use autoprefixer #{dest} -o #{dest}")

        puts "Built: #{versioned}"
      end

      # Convert extension
      def destination(file)
        super(file).sub(/(\.css)?\.s[ca]ss$/i,'.css')
      end
    end
  end
end

