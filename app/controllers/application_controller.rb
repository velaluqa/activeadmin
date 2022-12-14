require 'exceptions'

class ApplicationController < ActionController::Base
  impersonates :user

  def authorize_one!(actions, subject)
    unless actions.any? { |a| can?(a, subject) }
      raise CanCan::AccessDenied.new(current_user, actions, subject)
    end
  end

  def authorize_combination!(*combinations)
    unless combinations.any? { |a, s| can?(a, s) }
      raise CanCan::AccessDenied.new(current_user, combinations)
    end
  end

  before_action(:authenticate_user_from_token!)
  before_action(:ensure_valid_password, if: proc { current_user && current_user.id == true_user.id })
  before_action(:ensure_valid_keypair, if: proc { current_user && current_user.id == true_user.id })
  before_action(:set_paper_trail_whodunnit)

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
      format.html { redirect_to '/admin/not_authorized' }
      format.json { render json: { error_code: 403, error_message: 'Forbidden' }, status: :forbidden }
    end
  end

  def current_ability
    @current_ability ||= ::Ability.new(current_user)
  end

  def after_sign_in_path_for(_resource)
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
    return if current_user.has_valid_password?

    session[:after_validity_check_path] = request.fullpath
    respond_to do |format|
      format.html { redirect_to(users_change_password_path) }
      format.json { render(json: { success: false, error: 'Password expired', error_code: 23 }, status: :unauthorized) }
    end
  end

  def ensure_valid_keypair
    return if current_user.has_valid_keypair?

    session[:after_validity_check_path] = request.fullpath
    respond_to do |format|
      format.html { redirect_to(users_ensure_keypair_path) }
      format.json { render(json: { success: false, error: 'Password expired', error_code: 23 }, status: :unauthorized) }
    end
  end

  def render_react(pack_name, options = {})
    layout = options[:layout] || "external_react_spa"

    @pack_name = pack_name
    @component_props =
      options
        .except(:layout)
        .deep_transform_keys { |key| key.to_s.camelize(:lower) }

    render "v1/general/react_pack", layout: layout
  end

  def render_react_component(pack_name, options = {})
    component_props =
      options
        .except(:layout)
        .deep_transform_keys { |key| key.to_s.camelize(:lower) }

    render(
      partial: "v1/general/react_pack_component",
      locals: {
        pack_name: pack_name,
        component_props: component_props
      }
    )
  end

  def info_for_paper_trail
    { comment: params[:versions_comment] }
  end
end
