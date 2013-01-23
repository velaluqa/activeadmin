require 'exceptions'

class ApplicationController < ActionController::Base
  protect_from_forgery
  #check_authorization

  rescue_from Exceptions::FormNotFoundError do |exception|
    messages = ["The requested form '#{exception.form_name}' at version #{exception.form_version} for case #{exception.case} could not be found.", "Please contact staff"]

    render 'exceptions/not_found', :layout => 'client_errors', :locals => { :messages => messages, :exception_name => 'Form not found'}
  end
  rescue_from Exceptions::CaseNotFoundError do |exception|
    messages = ["The requested case #{exception.case_id} could not be found.", "Please contact staff"]

    render 'exceptions/not_found', :layout => 'client_errors', :locals => { :messages => messages, :exception_name => 'Case not found'}
  end

  rescue_from CanCan::AccessDenied do |exception|
    respond_to do |format|
      format.html { redirect_to admin_dashboard_path, :alert => exception.message }
      format.json { render :json => {:error_code => -1, :error => exception.message} }
    end
  end

  def current_ability
    @current_ability ||= Ability.new(current_user)
  end
end
