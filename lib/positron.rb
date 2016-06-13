require "yaml"
require 'pp'

require "positron/version"
require "positron/config"
require "positron/build"
require "positron/watch"
require "positron/help"
require "positron/npm"

module Positron
  extend self

  def run(options)
    config(options)

    case config[:command]
    when 'init' 
      Config.write(options)
    when 'npm' 
      NPM.setup
    when 'build'
      Build.run
    when 'watch'
      Watch.run
    else
      puts "Command `#{config[:command]}` not recognized"
    end
  end

  def config(options={})
    @config ||= Config.load(options)
  end

  def gzip(glob)
    Dir["#{Dir.pwd}/#{glob}"].each do |f|
      next unless f =~ ZIP_TYPES

      mtime = File.mtime(f)
      gz_file = "#{f}.gz"
      next if File.exist?(gz_file) && File.mtime(gz_file) >= mtime

      File.open(gz_file, "wb") do |dest|
        gz = Zlib::GzipWriter.new(dest, Zlib::BEST_COMPRESSION)
        gz.mtime = mtime.to_i
        IO.copy_stream(open(f), gz)
        gz.close
      end

      File.utime(mtime, mtime, gz_file)
    end
  end

end
