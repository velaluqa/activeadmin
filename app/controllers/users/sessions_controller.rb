class Users::SessionsController < Devise::SessionsController
  DeviseController.respond_to :json

  skip_before_filter :verify_authenticity_token, only: :authenticate_user

  after_filter :generate_csrf_token, only: :create # force generation of a CSRF token on login

  def new
    @dont_display_navbar = true
    super
  end

  def authenticate_user
    username = params[:user][:username]
    password = params[:user][:password]
    session_id = params[:session_id]

    user = User.find_for_authentication(username: username)
    if user.nil? || !user.valid_password?(password)
      render json: { error: 'Invalid credentials', error_code: 1 }
      return
    end

    session = Session.find(session_id)
    is_session_admin = can?(:manage, session)

    render json: { error_code: 0, success: true, is_session_admin: is_session_admin }
  end

  protected

  def generate_csrf_token
    form_authenticity_token
  end
end
