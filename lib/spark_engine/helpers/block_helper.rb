# From: https://github.com/nachokb/block_helpers
# Inlined becuase the project is inactive and current forks aren't published to RubyGems.org
#
module SparkEngine

  class BlockHelper

    class << self

      def parent_accessor
        @parent_accessor ||= respond_to?(:module_parent) ? :module_parent : :parent
      end

      def inherited(klass)
        # Define the helper method
        # e.g. for a class:
        #   class HelloHelper < BlockHelpers::Base
        #     #.....
        #   end
        #
        # then we define a helper method 'hello_helper'
        #
        method_name = klass.name.split('::').last.underscore
        klass.send(parent_accessor).class_eval %(
          def #{method_name}(*args, &block)

            # Get the current helper object which has all the normal helper methods
            if self.is_a?(SparkEngine::BlockHelper)
              top_level_helper = self.helper
              parent_block_helper = self
            else
              top_level_helper = self
              parent_block_helper = nil
            end

            # We need to save the current helper and parent block helper in the class so that
            # it's visible to the renderer's 'initialize' method...
            #{klass.name}.current_helper = top_level_helper
            #{klass.name}.current_parent_block_helper = parent_block_helper
            renderer = #{klass.name}.new(*args)

            # ...then set them anyway on the renderer so that renderer methods can use it
            renderer.send(:helper=, top_level_helper)
            renderer.send(:#{parent_accessor}=, parent_block_helper)

            body = block ? capture(renderer, &block) : nil

            if processed_body = renderer.display(body)
              return processed_body
            end
          end
        )
      end

      attr_accessor :current_helper, :current_parent_block_helper

    end

    def display(body)
      body
    end

    def respond_to?(method, include_all = false)
      super or helper.respond_to?(method, include_all)
    end

    protected

    attr_writer :helper, :"#{parent_accessor}"

    # For nested block helpers
    define_method :"#{parent_accessor}" do
      unless instance_variable_get("@#{parent_accessor}")
        instance_variable_set("@#{parent_accessor}", self.class.current_parent_block_helper)
      end
      instance_variable_get("@#{parent_accessor}")
    end

    def helper
      @helper ||= self.class.current_helper
    end

    def method_missing(method, *args, &block)
      if helper.respond_to?(method)
        self.class_eval "def #{method}(*args, &block); helper.send('#{method}', *args, &block); end"
        self.send(method, *args, &block)
      else
        super
      end
    end

    def capture(*args)
      # ActiveSupport 3.1 breaks capture method (defines it on all objects)
      # so we have to resort to rewrite it
      value = nil
      buffer = with_output_buffer { value = yield(*args) }
      if string = buffer.presence || value and string.is_a?(String)
        ERB::Util.html_escape string
      end
    end
  end

end

