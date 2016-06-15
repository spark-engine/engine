Gem.loaded_specs['megatron'].dependencies.each do |d|
  require d.name
end

require "megatron/version"
require "megatron/config"
require "megatron/command"

# Rails hooks
require "megatron/rails/helper"
require "megatron/rails/engine"

module Megatron
  extend self

  def config(options={})
    @config ||= Config.load(options)
  end

  def production
    ENV['CI'] || ENV['RAILS_ENV'] == 'production'
  end

  def root(name=nil)
    name ||= config[:name]
    Gem.loaded_specs[name.downcase].full_gem_path
  end
end
