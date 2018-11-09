class DocsController < ApplicationController
  def show
    page = params[:page]

    %w(docs).each do | root_page |
      if page.match(/#{root_page}\/?$/)
        page = File.join(root_page, 'index')
      end
    end

    if template_exists? page
      render template: page
    elsif template_exists? "docs/\#{page}"
      render template: "docs/\#{page}"
    else
      render file: "404.html", status: :not_found
    end
  end
end
