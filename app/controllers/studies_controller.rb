class StudiesController < ApplicationController
  before_filter :load_studies

  def index
    respond_to do |format|
      format.json { render :json => @studies}
    end
  end

  protected
  
  def load_studies
    authorize! :read, Study
    @studies = Study.accessible_by(current_ability)    
  end
end
