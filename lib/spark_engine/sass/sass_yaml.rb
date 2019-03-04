require 'yaml'

module SassC
  class SassYaml

    # Global vars beginning with underscore will have their children promoted to globals
    # and will be assigned without the underscore
    #
    # For example: _colors: { yellow: '#fco' }
    #     becomes: colors: { yellow: '#fco'}, yellow: '#fco'
    #
    #
    def initialize(options={})
      @content = options[:content]

      if options[:file] && File.exist?(options[:file])
        @content = File.open(options[:file], 'rb') { |f| f.read }
      end

      @data = promote_keys YAML.load(@content)
    end

    # Flatten dollar values and promote keys before returning YAML
    def to_yaml
      promote_keys YAML.load(convert_dollar_values)
    end

    # Convert each key to $key and process each value to a 
    # Sass data structure (creating maps, lists, strings)
    def to_sass
      @data.map { |key, value| 
        "$#{key}: #{convert_to_sass_value(value)};" 
      }.join("\n")
    end

    # If underscore keys, copy children to top level vars too
    # Input:
    #   _colors:
    #     yellow: '#fco'
    # Output:
    #   colors: { yellow: '#fco' }
    #   yellow: '#fco'
    #
    def promote_keys( data )
      data.keys.select{|k| k.start_with?('_') }.each do |key|
        data[key.sub(/^_/,'')] = data[key]
        data = data.delete(key).merge(data)
      end

      data
    end
    
    # Allow vars to reference other vars in their value with $
    # Example Input:¬
    #   blue: 'blue'¬
    #   green: 'green'
    #   gradient: [$blue, $green]
    # Output:
    #   blue: 'blue'¬
    #   green: 'green'
    #   gradient: ['blue', 'green']
    #
    def convert_dollar_values
      @content.gsub(/\$(?<var>\w+)/) {
        @data[$~[:var]].inspect
      }
    end
    
    # Convert
    def convert_to_sass_value(item)
      if item.is_a? Array
        make_list(item)
      elsif item.is_a? Hash
        make_map(item)
      else
        item.to_s
      end
    end

    # Convert arrays to Sass list syntax
    def make_list(item)
      '(' + item.map { |i| convert_to_sass_value(i) }.join(',') + ')'
    end

    # Convert hashes to Sass map syntax
    def make_map(item)
      '(' + item.map {|key, value| key.to_s + ':' + convert_to_sass_value(value) }.join(',') + ')'
    end  
  end
end
