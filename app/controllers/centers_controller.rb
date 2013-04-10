class CentersController < ApplicationController
  before_filter :load_centers

  def index
    respond_to do |format|
      format.json { render :json => @centers}
    end
  end

  protected

  def load_centers
    @study = Study.find(params[:study_id])
    authorize! :read, @study

    authorize! :read, Center
    @centers = @study.centers.accessible_by(current_ability)
  end
end
