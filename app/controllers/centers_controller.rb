class CentersController < ApplicationController
  before_filter :load_study, :only => [:index, :create]
  before_filter :load_centers, :only => [:index]
  before_filter :load_the_center, :only => [:wado_query]

  skip_before_filter :verify_authenticity_token, :only => [:create]

  def index
    respond_to do |format|
      format.json { render :json => @centers}
    end
  end

  def create
    authorize! :create, Center

    center = Center.create(:name => params[:center][:name], :code => params[:center][:code], :study => @study)

    respond_to do |format|
      format.json { render :json => {:success => !center.nil?, :center => center} }
    end
  end

  def wado_query
    @patients = @center.wado_query

    @authentication_token = current_user.authentication_token
    respond_to do |format|
      format.xml { render 'shared/wado_query' }
    end
  end

  protected

  def load_study
    @study = Study.find(params[:study_id])
    authorize! :read, @study
  end

  def load_centers
    authorize! :read, Center
    @centers = @study.centers.accessible_by(current_ability).order('code asc')
  end

  def load_the_center
    @center = Center.find(params[:id])
    authorize! :manage, @center
  end
end
