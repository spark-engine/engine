module Megatron
  class Engine < ::Rails::Engine
    config.generators do |g|
      g.assets false
      g.helper false
    end

    initializer "megatron.static_assets" do |app|
      app.middleware.insert_before(::ActionDispatch::Static, ::ActionDispatch::Static, Megatron.config[:output_dir])
    end

    initializer 'megatron.assets' do |app|
      Rails.application.config.assets.paths << Megatron.config[:stylesheets_dir]
    end

    # initializer 'megatron.form_builder' do |app|
    #   ActionView::Base.default_form_builder = Megatron::Form
    # end

    #initializer "megatron.errors" do |app|
      #Gaffe.configure do |config|
        #config.errors_controller = 'Megatron::ErrorsController'
      #end
      #Gaffe.enable!
    #end
  end
end

