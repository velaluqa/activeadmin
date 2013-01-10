class Users::SessionsController < Devise::SessionsController
  def new
    @dont_display_navbar = true
    super
  end

  def authenticate_user
    email = params[:user][:email]
    password = params[:user][:password]
    session_id = params[:session_id]

    user = User.find_for_authentication(:email => email)
    if user.nil? or !user.valid_password?(password)
      render :json => {:error => "Invalid credentials", :error_code => 1}
      return
    end

    #session = Session.find(session_id)
    #is_session_admin = (can? :manage, session)
    is_session_admin = user.is_app_admin?

    render :json => {:error_code => 0, :success => true, :is_session_admin => is_session_admin}
  end
end
