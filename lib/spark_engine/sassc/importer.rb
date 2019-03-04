require 'sassc'
require_relative 'extension'

module SassC
  module SparkEngine
    class Importer < SassC::Importer

      EXTENSIONS = [
        SassYamlExtension.new,
        Extension.new(".scss"),
        Extension.new(".sass"),
      ]

      PREFIXS = [ "", "_" ]
      GLOB = /(\A|\/)(\*|\*\*\/\*)\z/

      def imports(path, parent_path)
        parent_dir, _ = File.split(parent_path)
        specified_dir, specified_file = File.split(path)
        
        if m = path.match(GLOB)
          path = path.sub(m[0], "")
          base = File.expand_path(path, File.dirname(parent_path))
          return glob_imports(base, m[2], parent_path)
        end

        search_paths = ([parent_dir] + load_paths).uniq

        if specified_dir != "."
          search_paths.map! do |path|
            File.join(path, specified_dir)
          end
          search_paths.select! do |path|
            File.directory?(path)
          end
        end

        search_paths.each do |search_path|
          PREFIXS.each do |prefix|
            file_name = prefix + specified_file

            EXTENSIONS.each do |extension|
              try_path = File.join(search_path, file_name + extension.postfix)
              if File.exist?(try_path)
                return extension.import_for(try_path, parent_dir, options)
              end
            end
          end
        end

        SassC::Importer::Import.new(path)
      end

      def extension_for_file(file)
        EXTENSIONS.detect do |extension|
          file.include? extension.postfix
        end
      end

      def load_paths
        options[:load_paths]
      end

      def glob_imports(base, glob, current_file)
        files = globbed_files(base, glob)
        files = files.reject { |f| f == current_file }

        files.map do |filename|
          extension = extension_for_file(filename)
          extension.import_for(filename, base, options)
        end
      end

      def globbed_files(base, glob)
        # TODO: Raise an error from SassC here
        raise ArgumentError unless glob == "*" || glob == "**/*"

        extensions = EXTENSIONS.map(&:postfix)
        exts = extensions.map { |ext| Regexp.escape("#{ext}") }.join("|")
        sass_re = Regexp.compile("(#{exts})$")

        files = Dir["#{base}/#{glob}"].sort.map do |path|
          if File.directory?(path)
            nil
          elsif sass_re =~ path
            path
          end
        end

        files.compact
      end
    end
  end
end
