class UsersController < ApplicationController
  before_filter :authenticate_user!

  def show
    5.times { puts '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!' }

    #TODO: check authorization via cancan (manage users right)
    if(params[:id] == 'me')
      params[:id] = current_user.id
    elsif(params[:id].to_i != current_user.id)
      flash[:error] = "You are only allowed to access your own user"
      redirect_to :controller => 'admin/dashboard', :action => 'index'
      return
    end
    
    @user = User.find(params[:id])

    respond_to do |format|
      format.json { render :json => @user }
    end
  end
end
