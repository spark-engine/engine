require 'fileutils'
require "cyborg/command/npm"

module Cyborg
  class Scaffold
    attr_reader :gem, :engine, :namespace, :plugin_module, :path, :gemspec_path

    def initialize(options)
      @cwd = File.expand_path(File.dirname(options[:name]))
      @gem = underscorize(File.basename(options[:name]))
      @engine = underscorize(options[:engine] || @gem)
      @namespace = @engine
      @plugin_module = modulize @engine
      @gem_module = modulize @gem

      FileUtils.mkdir_p @cwd

      Dir.chdir @cwd do
        puts "Creating new plugin #{@namespace}".bold
        engine_site_scaffold

        @gemspec_path = new_gem
        @spec = Gem::Specification.load(@gemspec_path)
        @path = File.expand_path(File.dirname(@gemspec_path))

        engine_copy
        bootstrap_gem
        setup_package_json
        update_git
      end
    end

    # Create a new gem with Bundle's gem command
    #
    def new_gem
      system "bundler gem #{gem}"
      Dir.glob(File.join(gem, "/*.gemspec")).first
    end

    def setup_package_json
      Dir.chdir path do
        NPM.setup
      end
    end

    def bootstrap_gem

      # Remove bin
      FileUtils.rm_rf(File.join(path, 'bin'))

      scaffold_path = File.expand_path("scaffold/**/*", File.dirname(__FILE__))

      Dir.glob(scaffold_path, File::FNM_DOTMATCH).select{|f| File.file? f}.each do |f|
        write_template f.split(/cyborg\/scaffold\//)[1]
      end

      FileUtils.chmod '+x', "#{gem}/bin/#{engine}"
    end

    # Create an Rails plugin engine for documentation site
    def engine_site_scaffold
      FileUtils.mkdir_p(".#{gem}-tmp")
      Dir.chdir ".#{gem}-tmp" do
        response = Open3.capture3("rails plugin new #{gem} --mountable --dummy-path=site --skip-test-unit")
        if !response[1].empty?
          puts response[1]
          abort "FAILED: Please be sure you have the rails gem installed with `gem install rails`"
        end
      end
    end

    # Copy site scaffold into site sub directory
    def engine_copy
      site_path = File.join(path, 'site')
      FileUtils.mkdir_p(site_path)

      Dir.chdir ".#{gem}-tmp/#{gem}" do
        %w(app config bin config.ru Rakefile public log).each do |item|
          target = File.join(site_path, item)

          FileUtils.cp_r(File.join('site', item), target)
          action_log "create", target.sub(@cwd+'/','')
        end

      end

      FileUtils.rm_rf(".#{gem}-tmp")

      # Remove files and directories that are unnecessary for the
      # light-weight Rails documentation site
      remove = %w(mailers models assets channels jobs layouts).map{ |f| File.join('app' f) }
      remove.concat %w(cable.yml storage.yml database.yml).map{ |f| File.join('config' f) }

      remove.each do |item|
        FileUtils.rm_rf(File.join(site_path, item))
      end
    end

    def update_git
      Dir.chdir gem do
        system "git reset"
        system "git add -A"
      end
    end

    def gemspec
%Q{# coding: utf-8
$:.push File.expand_path("../lib", __FILE__)

require "#{spec.name}/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = "#{spec.name}"
  spec.version     = #{@gem_module}::VERSION
  spec.authors     = #{spec.authors}
  spec.email       = #{spec.email}
  spec.summary     = "Summary of your gem."
  spec.description = "Description of your gem (usually longer)."
  spec.license     = "#{spec.license}"
  spec.bindir      = 'bin'

  spec.files         = Dir["{app,bin,lib,public,config}/**/*", "LICENSE.txt", "README.md"]
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "rails", ">= 4"
  spec.add_runtime_dependency "cyborg"

  spec.add_development_dependency "bundler", "~> 1.12"
  spec.add_development_dependency "rake", "~> 10.0"
end
}
    end

    def write_template(template, target=nil)
      template_path = File.expand_path("scaffold/#{template}", File.dirname(__FILE__))

      # Extract file extension
      ext = File.extname(template)

      # Replace keywords with correct names (excluding file extensions)
      target_path = template.sub(/#{ext}$/, '').gsub(/(gem|engine|namespace)/, { 
        'gem' => @gem, 
        'engine' => @engine,
        'namespace' => @namespace
      }) + ext

      write_file target_path, read_template(template_path)
    end

    def read_template(file_path)
      contents = ''
      File.open file_path do |f|
        contents = ERB.new(f.read).result(binding)
      end
      contents
    end

    def write_file(paths, content='', mode='w')
      paths = [paths].flatten
      paths.each do |path|
        if File.exist?(path)
          type = 'update'
        else
          FileUtils.mkdir_p(File.dirname(path))
          type = 'create'
        end

        File.open path, mode do |io|
          io.write(content)
        end

        action_log(type, path)
      end
    end

    def action_log(action, path)
      puts action.rjust(12).colorize(:green).bold + "  #{path}"
    end

    def modulize(input)
      input.split('_').collect { |name|
        (name =~ /[A-Z]/) ? name : name.capitalize
      }.join
    end

    def underscorize(input)
      input.gsub(/[A-Z]/) do |char|
        '_'+char
      end.sub(/^_/,'').downcase
    end
  end
end
