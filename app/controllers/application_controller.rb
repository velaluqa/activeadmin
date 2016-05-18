require 'exceptions'

class ApplicationController < ActionController::Base
  before_filter :authenticate_user_from_token!
  
  protect_from_forgery

  helper_method :current_ability
  
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

  def access_denied(*_args)
    respond_to do |format|
      format.html { render 'shared/forbidden', status: :forbidden, layout: 'active_admin' }
      format.json { render json: { error_code: 403, error_message: "Forbidden" }, status: :forbidden  }
    end
  end
  
  def current_ability
    @current_ability ||= ::Ability.new(current_user)
  end

  def after_sign_in_path_for(resource)
    admin_root_path
  end#

  protected
  
  def authenticate_user_from_token!
    username = request.headers['HTTP_X_SESSION_USERNAME']
    token    = request.headers['HTTP_X_SESSION_TOKEN']
    user     = username && User.find_by_username(username)

    # Notice how we use Devise.secure_compare to compare the token
    # in the database with the token given in the params, mitigating
    # timing attacks.
    # See: https://gist.github.com/josevalim/fb706b1e933ef01e4fb6
    if user && Devise.secure_compare(user.authentication_token, token)
      env['devise.skip_trackable'] = true
      sign_in user, store: false
    end
  end
end
