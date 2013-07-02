require 'exceptions'

class UsersController < ActionController::Base
  before_filter :authenticate_user!
  before_filter :set_user

  layout 'application'

  def change_password
    @dont_display_navbar = true
  end

  def update_password
    if(params[:user][:current_password] == params[:user][:password])
      flash[:error] = 'You cannot choose the same password again.'
      respond_to do |format|
        format.html { redirect_to users_change_password_path }
        format.json { render :json => {:success => false, :error_code => 1, :error => 'You cannot choose the same password again.'}, :status => :bad_request }
      end
      return
    end

    if @user.update_with_password({:current_password => params[:user][:current_password], :password => params[:user][:password], :password_confirmation => params[:user][:password_confirmation], :password_changed_at => Time.now})
      sign_in @user, :bypass => true
      
      respond_to do |format|
        format.html { redirect_to root_path, :notice => 'Your password was changed successfully.' }
        format.json { render :json => {:success => true, :user => @user} }
      end      
    else
      error_messages = '<ul>'+@user.errors.full_messages.map {|msg| '<li>'+msg+'</li>'}.join('')+'<ul>'
      flash[:error] = ('Your password could not be updated:'+error_messages).html_safe

      respond_to do |format|
        format.html { redirect_to users_change_password_path }
        format.json { render :json => {:success => false, :error_code => 1, :error => @user.errors.full_messages.join("\n")}, :status => :bad_request }
      end      
    end    
  end

  def cancel_current_cases
    cases = @user.current_cases.reject {|c| c.state != :in_progress and c.state != :reopened_in_progress}

    cases.each do |c|
      case c.state
      when :in_progress
        c.state = :unread
      when :reopened_in_progress
        c.state = :reopened
      end

      c.current_reader = nil
      c.save
    end

    respond_to do |format|
      format.json { render :json => {:success => true } }
    end
  end
  
  protected
  
  def set_user
    @user = current_user
  end
end
