module Megatron
  module Assets
    class Css < Megatron::Asset
      @@type = :stylesheets
      @@extension = 'css'

      def build
        dest = destination
        system "cp #{path} #{dest}"
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

