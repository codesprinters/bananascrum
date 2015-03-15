class ThemesController < ApplicationController
  def show
    @theme = Theme.find_by_slug params[:slug]
    response.headers["Content-Type"] = "text/css"
    render :template => 'themes/show', :layout => false
  end
end
