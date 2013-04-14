class CentersController < ApplicationController
  before_filter :load_study
  before_filter :load_centers, :only => :index

  skip_before_filter :verify_authenticity_token, :only => [:create]

  def index
    respond_to do |format|
      format.json { render :json => @centers}
    end
  end

  def create
    authorize! :create, Center

    center = Center.create(:name => params[:center][:name], :study => @study)

    respond_to do |format|
      format.json { render :json => {:success => !center.nil?, :center => center} }
    end
  end

  protected

  def load_study
    @study = Study.find(params[:study_id])
    authorize! :read, @study
  end

  def load_centers
    authorize! :read, Center
    @centers = @study.centers.accessible_by(current_ability)
  end
end
