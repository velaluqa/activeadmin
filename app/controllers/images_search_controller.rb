class ImagesSearchController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:search]

  def search
    authorize! :image_manage, :system

    term = params[:term]
    if(term.length < 3)
      respond_to do |format|
        format.json { render :json => {:success => false, :error_message => 'Search term is too short.'} }
      end
      return
    end

    results = ImagesSearch.perform_search(term)

    respond_to do |format|
      format.json { render :json => {:success => true, :results => results} }
    end
  end
end
