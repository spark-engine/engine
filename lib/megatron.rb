Gem.loaded_specs['megatron'].dependencies.each do |d|
  require d.name
end

require "megatron/version"
require "megatron/command"
require "megatron/plugin"
require "megatron/assets"

module Megatron
  extend self

  def production?
    ENV['CI'] || ENV['RAILS_ENV'] == 'production'
  end

  def self.load_helpers
    Megatron::Helpers.constants.each do |c|
      helper = Megatron::Helpers.const_get(c)
      ActionView::Base.send :include, helper if defined? ActionView::Base
    end
  end
end
