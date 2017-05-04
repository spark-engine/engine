require 'sass'
require 'yaml'

module Cyborg
  module SassParser
    extend self

    # Global vars beginning with underscore will have their children promoted to globals
    # and will be assigned without the underscore
    #
    # For example: _colors: { yellow: '#fco' }
    #     becomes: colors: { yellow: '#fco'}, yellow: '#fco'
    #
    #
    def load_yaml(data)
      promote_globals YAML.load(data)
    end

    def read_file(file)
      IO.read(file)
    end

    def promote_globals( data )
      data.keys.select{|k| k.start_with?('_') }.each do |key|
        data[key.sub(/^_/,'')] = data[key]
        data = data.delete(key).merge(data)
      end

      data
    end

    def expand_vars(file)
      content   = read_file(file)
      file_data = load_yaml(content)

      content = content.gsub(/\$(?<var>\w+)/) do
        file_data[$~[:var]].inspect
      end

      load_yaml content
    end

    def parse(file)
      expand_vars file
    end
  end

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
      return unless yaml? name

      full_filename, syntax = Sass::Util.destructure(find_real_file(dir, name, options))
      return unless full_filename && File.readable?(full_filename)

      yaml       = SassParser.parse(full_filename)
      variables  = yaml.map { |key, value| "$#{key}: #{_convert_to_sass(value)};" }.join("\n")

      Sass::Engine.new(variables, options.merge(
          :filename => full_filename,
          :importer => self,
          :syntax   => :scss
      ))
    end

    def _convert_to_sass(item)
      if item.is_a? Array
        _make_list(item)
      elsif item.is_a? Hash
        _make_map(item)
      else
        item.to_s
      end
    end

    def _make_list(item)
      '(' + item.map { |i| _convert_to_sass(i) }.join(',') + ')'
    end

    def _make_map(item)
      '(' + item.map {|key, value| key.to_s + ':' + _convert_to_sass(value) }.join(',') + ')'
    end
  end

end

