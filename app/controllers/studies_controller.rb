class StudiesController < ApplicationController
  before_filter :load_studies, :only => [:index]
  before_filter :load_the_study, :only => [:wado_query]

  def index
    respond_to do |format|
      format.json { render :json => @studies}
    end
  end

  def wado_query
    @patients = @study.wado_query

    @authentication_token = current_user.authentication_token
    respond_to do |format|
      format.xml { render 'shared/wado_query' }
    end
  end

  protected

  def load_studies
    authorize! :read, Study
    @studies = Study.accessible_by(current_ability)
  end

  def load_the_study
    @study = Study.find(params[:id])
    authorize! :manage, @study
  end
end
