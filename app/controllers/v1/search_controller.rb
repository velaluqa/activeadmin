require 'record_search'

class V1::SearchController < ApplicationController
  before_action :authenticate_user!

  def index
    @search = RecordSearch.new(
      user: current_user,
      query: params['query'],
      models: Array(params['models'].try(:split, ','))
    )
    render status: :ok, json: @search.results
  rescue => e
    render json: { errors: e }, status: :unprocessable_entity
  end
end
