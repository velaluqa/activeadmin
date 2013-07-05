ActiveAdmin.register User do

  controller do
    def create
      private_key_password = params[:user][:signature_password]
      if(private_key_password != params[:user][:signature_password_confirmation])
        flash[:error] = 'Signature password doesn\'t match confirmation'
        redirect_to :back
        return
      elsif(private_key_password == params[:user][:password])
        flash[:error] = 'Signature password must be different from login password'
        redirect_to :back
        return
      elsif(private_key_password.length < 6)
        flash[:error] = 'Signature password must be at least 6 characters'
        redirect_to :back
        return
      end

      create!
      @user.generate_keypair(private_key_password, true)
    end
  end

  index do
    selectable_column
    column :name, :sortable => :name do |user|
      link_to user.name, admin_user_path(user)
    end
    column :username
    column :key_pair do |user|
      if(user.public_key.nil? or user.private_key.nil?)
        status_tag("Missing", :error)
      else
        status_tag("Present", :ok)
      end
    end
    column :locked do |user|
      if(user.access_locked?)
        status_tag('Locked', :error)
      else
        status_tag('Unlocked', :ok)
      end
    end
    default_actions
  end

  show do |user|
    attributes_table do
      row :name
      row :username
      row :sign_in_count
      row :currently_signed_in do
        if(user.current_sign_in_at.nil?)
          "No"
        else
          "Yes, since #{pretty_format(user.current_sign_in_at)} from #{user.current_sign_in_ip}"
        end
      end
      row :last_sign_in do
        if(user.last_sign_in_at.nil?)
          "Never"
        else
          "#{pretty_format(user.last_sign_in_at)} from #{user.last_sign_in_ip}"
        end
      end
      row :failed_attempts
      row :locked do
        if(user.access_locked?)
          status_tag("Locked at #{pretty_format(user.locked_at)}", :error)
        else
          status_tag('Unlocked', :ok)
        end
      end
      row :public_key do
        if user.public_key.nil?
          status_tag("Missing", :error)
        else
          link_to 'Download Public Key', download_public_key_admin_user_path(user)
        end
      end
      row :private_key do
        if user.private_key.nil?
          status_tag("Missing", :error)
        else
          link_to 'Download Private Key', download_private_key_admin_user_path(user)
        end
      end
    end
  end

  form do |f|
    f.inputs 'User Information' do
      f.input :username
      f.input :name
      if(current_user.is_app_admin? or not f.object.persisted?)
        f.input :password
        f.input :password_confirmation
      end
      unless f.object.persisted?
        f.input :signature_password, :required => true
        f.input :signature_password_confirmation, :required => true
      end
      f.form_buffers.last # https://github.com/gregbell/active_admin/pull/965
    end

    f.buttons
  end

  # filters
  filter :username
  filter :name

  member_action :download_public_key do
    @user = User.find(params[:id])
    
    send_data @user.public_key, :filename => "#{@user.username}.pub" unless @user.public_key.nil?
  end
  member_action :download_private_key do
    @user = User.find(params[:id])
    
    send_data @user.private_key, :filename => "#{@user.username}.key" unless @user.private_key.nil?
  end

  member_action :generate_keypair, :method => :post do
    if (params[:user][:password].nil? or params[:user][:password].empty?)
      flash[:error] = 'You must supply a password for the private key'
      redirect_to :action => :show
      return
    end

    @user = User.find(params[:id])
    @user.generate_keypair(params[:user][:password])

    redirect_to({:action => :show}, :notice => 'New keypair successfully generated')
  end
  member_action :generate_keypair_form, :method => :get do
    @user = User.find(params[:id])

    @page_title = 'Generate new keypair'
    render 'admin/users/generate_keypair'
  end

  action_item :only => :show do
    link_to 'Generate new keypair', generate_keypair_form_admin_user_path(resource), :confirm => 'Generating a new keypair will invalidate all past signatures by this user. Are you sure you want to do this?'
  end

  member_action :unlock, :method => :get do
    authorize! :manage, :system

    resource.unlock_access! if resource.access_locked?
    redirect_to({:action => :show}, :notice => 'User unlocked!')
  end

  action_item :only => :show do
    link_to 'Unlock', unlock_admin_user_path(resource) if(can? :manage, :system and resource.access_locked?)
  end

  action_item :only => :show do
    link_to('Audit Trail', admin_versions_path(:audit_trail_view_type => 'user', :audit_trail_view_id => resource.id))
  end
end
