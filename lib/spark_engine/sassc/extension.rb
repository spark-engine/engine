require "spark_engine/sass/sass_yaml"

module SassC
  module SparkEngine
    class Extension
      attr_reader :postfix

      def initialize(postfix=nil)
        @postfix = postfix
      end

      def import_for(full_path, parent_dir, options)
        SassC::Importer::Import.new(full_path)
      end
    end

    class SassYamlExtension < Extension
      def postfix
        ".yml"
      end

      def import_for(full_path, parent_dir, options={})
        parsed_scss = SassYaml.new(file: full_path).to_sass
        SassC::Importer::Import.new(full_path, source: parsed_scss)
      end
    end
  end
end
