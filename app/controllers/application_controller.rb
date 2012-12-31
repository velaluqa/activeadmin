require 'exceptions'

class ApplicationController < ActionController::Base
  protect_from_forgery

  rescue_from Exceptions::FormNotFoundError do |exception|
    messages = ["The requested form '#{exception.form_name}' at version #{exception.form_version} could not be found.", "Please contact staff"]

    render 'exceptions/form_not_found', :layout => 'client_errors', :locals => { :messages => messages, :exception_name => 'Form not found'}
  end
end
