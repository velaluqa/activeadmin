class V1::VisitsController < V1::ApiController
  def index
    authorize! :read, Visit

    @visits = Visit.accessible_by(current_ability).with_filter(params[:filter])
    @visits = @visits.where(patient_id: params[:patient_id]) if params[:patient_id]
  end
end
