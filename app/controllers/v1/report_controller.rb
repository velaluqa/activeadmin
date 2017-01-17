require_dependency 'report'

class V1::ReportController < V1::ApiController # :nodoc:
  before_action :authenticate_user!

  # The route GET /v1/report returns the results of the queried report
  # type and parameters.
  def index
    authorize!(:read_reports, Study)

    report = Report.create(
      type: report_type,
      params: params[:params] || {},
      user: current_user
    )

    render json: report.result
  end


  protected

  def report_type
    params.require(:type)
  end
end
