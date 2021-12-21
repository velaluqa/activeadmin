require 'record_search'

class V1::SearchController < ApplicationController
  before_action :authenticate_user!

  def index
    options = {
      user: current_user,
      query: params['query'],
      models: Array(params['models'].try(:split, ',')),
    }
    options[:study_id] = session['selected_study_id'] unless params["all_studies"] == "true"

    @search = RecordSearch.new(options)
    render status: :ok, json: @search.results
  rescue => e
    render json: { errors: e }, status: :unprocessable_entity
  end
end
