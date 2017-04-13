require 'exceptions'

class ApplicationController < ActionController::Base
  before_filter :authenticate_user_from_token!
  before_filter(:ensure_valid_password, if: proc { !current_user.nil? })
  before_filter(:ensure_valid_keypair, if: proc { !current_user.nil? })

  protect_from_forgery

  helper_method :current_ability

  rescue_from Exceptions::FormNotFoundError do |exception|
    main_message = "The requested form '#{exception.form_name}'"
    main_message += " for case #{exception.case}" unless exception.case.nil?
    main_message += ' could not be found.'
    messages = [main_message, 'Please contact staff']

    render(
      'exceptions/not_found',
      layout: 'client_errors',
      locals: {
        messages: messages,
        exception_name: 'Form not found'
      }
    )
  end

  rescue_from Exceptions::CaseNotFoundError do |exception|
    messages = [
      "The requested case #{exception.case_id} could not be found.",
      'Please contact staff'
    ]

    render(
      'exceptions/not_found',
      layout: 'client_errors',
      locals: {
        messages: messages,
        exception_name: 'Case not found'
      }
    )
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
  end

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

  def ensure_valid_password
    return true if current_user.has_valid_password?
    session[:after_validity_check_path] = request.fullpath
    respond_to do |format|
      format.html { redirect_to(users_change_password_path) }
      format.json { render(json: { success: false, error: 'Password expired', error_code: 23 }, status: :unauthorized) }
    end
  end

  def ensure_valid_keypair
    return true if current_user.has_valid_keypair?
    session[:after_validity_check_path] = request.fullpath
    respond_to do |format|
      format.html { redirect_to(users_ensure_keypair_path) }
      format.json { render(json: { success: false, error: 'Password expired', error_code: 23 }, status: :unauthorized) }
    end
  end
end
