# Extracted from sassc-rails
require "sassc-rails"
require "spark_engine/sass/sass_yaml"

module SassC
  module SparkEngine
    class Importer < SassC::Rails::Importer
      
      # Create a new importer to process yaml files
      class SassYamlExtension < Extension
        def postfix
          ".yml"
        end

        def import_for(full_path, parent_dir, options={})
          parsed_scss = SassYaml.new(file: full_path).to_sass
          SassC::Importer::Import.new(full_path, source: parsed_scss)
        end
      end

      # Inject importer into Rails 
      def imports(path, parent_path)
        EXTENSIONS << SassYamlExtension.new
        super(path, parent_path)
      end


      private

      def record_import_as_dependency(path)
        # Replace reference to sprockets for ease of use without Rails
        # environment
      end
      
    end
  end
end
