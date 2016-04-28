require 'exceptions'

class ApplicationController < ActionController::Base
  protect_from_forgery
  #check_authorization

  rescue_from Exceptions::FormNotFoundError do |exception|
    main_message = "The requested form '#{exception.form_name}'"
    main_message += " for case #{exception.case}" unless exception.case.nil?
    main_message += " could not be found."
    messages = [main_message, "Please contact staff"]

    render 'exceptions/not_found', :layout => 'client_errors', :locals => { :messages => messages, :exception_name => 'Form not found'}
  end
  rescue_from Exceptions::CaseNotFoundError do |exception|
    messages = ["The requested case #{exception.case_id} could not be found.", "Please contact staff"]

    render 'exceptions/not_found', :layout => 'client_errors', :locals => { :messages => messages, :exception_name => 'Case not found'}
  end

  before_filter do
    if(current_user and
       (
        current_user.password_changed_at.nil? or
        current_user.password_changed_at < Rails.application.config.max_allowed_password_age.ago
        ) and
       not
       (
        params[:controller] == 'users' and
        (params[:action] == 'change_password' or
        params[:action] == 'update_password')
        ) and
       not
       (
        params[:controller] == 'forms' and
        (params[:action] == 'show' or
         params[:action] == 'previous_results')
        ) and
       not
       (
        request.format == 'json' and not
        (params[:controller] == 'users/sessions' and params[:action] == 'create')
        )
       )
      respond_to do |format|
        format.html { redirect_to users_change_password_path }
        format.json { render :json => {:success => false, :error => 'Password expired', :error_code => 23}, :status => :unauthorized }
      end
      
      false
    else
      true
    end
  end

  def access_denied(args)
    respond_to do |format|
      format.html { render 'shared/forbidden', status: :forbidden, layout: 'active_admin' }
      format.json { render json: { error_code: 403, error_message: "Forbidden" }, status: :forbidden  }
    end
  end
  
  def current_ability
    @current_ability ||= ::Ability.new(current_user)
  end

  def after_sign_in_path_for(resource)
    if(current_user and current_user.has_system_role?(:image_manage))
      admin_studies_path
    else
      admin_root_path
    end
  end
end
