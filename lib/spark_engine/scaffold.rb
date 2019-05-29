require 'fileutils'
require "spark_engine/command/npm"

module SparkEngine
  class Scaffold
    attr_reader :gem, :engine, :namespace, :plugin_module, :path, :gemspec_path

    def initialize(options)
      require 'erb'
      @options = options

      return new_component(@options) if @options[:component]

      @cwd = File.expand_path(File.dirname(@options[:name]))
      @gem = underscorize(File.basename(@options[:name]))
      @engine = underscorize(@options[:engine] || @gem)
      @namespace = @engine
      @plugin_module = modulize @engine
      @gem_module = modulize @gem
      @gem_temp = ".#{@gem}-temp"

      if Dir.exist?(@options[:name]) && !@options[:force]
        return puts "Path #{@options[:name]} exists. Use --force to override"
      end

      FileUtils.mkdir_p @cwd

      Dir.chdir @cwd do
        puts "Creating new plugin #{@namespace}".bold

        @gemspec_path = new_gem
        @spec = Gem::Specification.load(@gemspec_path)
        @path = File.expand_path(File.dirname(@gemspec_path))

        engine_scaffold

        bootstrap_gem
        setup_package_json
        update_git
      end

      post_install
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
        write_template f.split(/spark_engine\/scaffold\//)[1], force: true
      end

      system 'bundle'
    end

    # Create an Rails plugin engine for documentation site
    def engine_scaffold
      FileUtils.mkdir_p(@gem_temp)
      Dir.chdir(@gem_temp) do
        response = Open3.capture3("rails plugin new #{gem} --mountable --dummy-path=site --skip-test-unit")
        if !response[1].empty?
          puts response[1]
          abort "FAILED: Please be sure you have the rails gem installed with `gem install rails`"
        end

        # Remove files and directories that are unnecessary for the
        # light-weight Rails documentation site
        remove = %w(mailers models assets channels jobs views).map{ |f| File.join('app', f) }
        remove.concat %w(cable.yml storage.yml database.yml).map{ |f| File.join('config', f) }

        remove.each { |f| FileUtils.rm_rf File.join(@gem, 'site', f), secure: true }
      end
      

      engine_copy
    end

    # Copy parts of the engine scaffold into site directory
    def engine_copy
      site_path = File.join path, 'site'
      FileUtils.mkdir_p site_path

      ## Copy Rails plugin files
      Dir.chdir "#{@gem_temp}/#{gem}/site" do
        %w(app config bin config.ru Rakefile public log).each do |item|
          target = File.join site_path, item

          FileUtils.cp_r item, target

          action_log "create", target.sub(@cwd+'/','')
        end

      end

      # Remove temp dir
      FileUtils.rm_rf @gem_temp
    end

    def update_git
      Dir.chdir gem do
        system "git reset"
        system "git add -A"
      end
    end

    def write_template(template, options)
      template_path = File.expand_path("scaffold/#{template}", File.dirname(__FILE__))

      # Extract file extension
      ext = File.extname(template)

      # Replace keywords with correct names (excluding file extensions)
      target_path = template.sub(/#{ext}$/, '').gsub(/(gem|engine|namespace)/, { 
        'gem' => @gem, 
        'engine' => @engine,
        'namespace' => @namespace
      }) + ext

      write_file target_path, read_template(template_path), options
    end

    def read_template(file_path)
      contents = ''
      File.open file_path do |f|
        contents = ERB.new(f.read).result(binding)
      end
      contents
    end

    def write_file(path, content='', options={})
      options[:mode] ||= 'w'

      if File.exist?(path) 
        if options[:force]
          type = 'update'
        else
          return action_log('skipped', path)
        end
      else
        type = 'create'
      end

      FileUtils.mkdir_p(File.dirname(path))

      if content.empty?
        FileUtils.touch(path)
      else
        File.open(path, options[:mode]) { |io| io.write(content) }
      end

      action_log(type, path)
    end

    def post_install
      require 'pathname'

      target = Pathname.new File.join(@cwd, @gem) 
      dir = target.relative_path_from Pathname.new(Dir.pwd)
      victory = "#{@plugin_module} Design System created at #{dir}. Huzzah!"
      dashes = ''
      victory.size.times{ dashes += '-' }

      puts "\n#{victory}\n#{dashes}".bold

      puts "Install dependencies:"
      puts "  - cd #{dir}"
      puts "  - bundle"
      puts "  - yarn install (or npm install)\n\n"
      puts "Then give it a spin.\n\n"
      puts "  spark build".bold + "  - builds assets"
      puts "  spark server".bold + " - view documentation site in a server"
      puts "  spark help".bold + "   - learn more…"
      puts dashes + "\n\n"
    end

    def new_component(options={})
      options = {
        sass: true,
        template: true,
        js: true
      }.merge(options)

      path = File.join(SparkEngine.plugin.paths[:components], options[:component])
      name = options[:component].split('/').last

      paths = {
        base: path,
        component: path+'_component.rb',
        template: File.join(path, "_#{name}.html.erb"),
        sass: File.join(SparkEngine.plugin.paths[:stylesheets], "components", "#{options[:component].sub(name, '_'+name)}.scss"),
        js: File.join(SparkEngine.plugin.paths[:javascripts], "components", "#{options[:component].sub(name, '_'+name)}.js")
      }

      if options[:delete]
        return paths.values.each do |p| 
          action_log('delete', FileUtils.rm_rf(p).first) if File.exist?(p)
        end
      end

      # Write component class
      component_content = %Q{class #{modulize(options[:component])}Component < #{options[:class] || 'SparkComponents::Component' }\nend} 
      write_file(paths[:component], component_content, options)

      write_file(paths[:template], '', options) if options[:template]
      write_file(paths[:sass], '', options)     if options[:sass]
      write_file(paths[:js], '', options)       if options[:js] 
    end


    def action_log(action, path)
      color = case action
              when 'create', 'update'
                :green
              when 'skip'
                :white
              when 'delete'
                :red
              end
      puts action.rjust(12).colorize(color).bold + "  #{path.sub(Dir.pwd+'/','')}"
    end

    def modulize(input)
      classify = lambda { |name| 
        name = (name =~ /_/) ? name.split('_').map(&classify).join : name
        (name =~ /[A-Z]/) ? name : name.capitalize 
      }
      input.split('/').map(&classify).join('::')
    end

    def underscorize(input)
      input.gsub(/[A-Z]/) do |char|
        '_'+char
      end.sub(/^_/,'').downcase
    end
  end
end
