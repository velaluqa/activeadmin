class ImagesSearchController < ApplicationController
  skip_before_filter :verify_authenticity_token, :only => [:search]

  def search
    authorize! :image_manage, :system unless can? :mqc, Visit

    term = params[:term]
    if(term.length < 3)
      respond_to do |format|
        format.json { render :json => {:success => false, :error_message => 'Search term is too short.'} }
      end
      return
    end

    results = ImagesSearch.perform_search(term)
    results_json = results.map do |result|
      {
        :text => result.text,
        :id => result.result_id,
        :type => result.result_type
      }
    end
    pp results_json

    respond_to do |format|
      format.json { render :json => {:success => true, :results => results_json} }
    end
  end
end
