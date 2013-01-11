require 'exceptions'

class ApplicationController < ActionController::Base
  protect_from_forgery

  rescue_from Exceptions::FormNotFoundError do |exception|
    messages = ["The requested form '#{exception.form_name}' at version #{exception.form_version} for case #{exception.case} could not be found.", "Please contact staff"]

    render 'exceptions/not_found', :layout => 'client_errors', :locals => { :messages => messages, :exception_name => 'Form not found'}
  end
  rescue_from Exceptions::CaseNotFoundError do |exception|
    messages = ["The requested case #{exception.case_id} could not be found.", "Please contact staff"]

    render 'exceptions/not_found', :layout => 'client_errors', :locals => { :messages => messages, :exception_name => 'Case not found'}
  end
end
