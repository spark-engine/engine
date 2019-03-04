require "spark_engine/sass/sass_yaml"

module SparkEngine
  class Importer < Sass::Importers::Filesystem

    def watched_file?(uri)
      !!(uri =~ /\.yml$/ &&
        uri.start_with?(root + File::SEPARATOR))
    end

    protected

    def extensions
      {'yml' => :scss}
    end

    def yaml?(name)
      File.extname(name) == '.yml'
    end

    private

    def _find(dir, name, options)
      full_filename, syntax = Sass::Util.destructure(find_real_file(dir, name, options))
      return unless full_filename && yaml?(full_filename) && File.readable?(full_filename)

      variables  = SassC::SassYaml.new(file: full_filename).to_sass

      Sass::Engine.new(variables, options.merge(
        :filename => full_filename,
        :importer => self,
        :syntax   => :scss
      ))
    end
  end

end

