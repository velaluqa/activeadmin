class Users::SessionsController < Devise::SessionsController
  def new
    @dont_display_navbar = true
    super
  end
end
