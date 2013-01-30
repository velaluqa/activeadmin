ActiveAdmin.register User do
  index do
    selectable_column
    column :name do |user|
      link_to user.name, admin_user_path(user)
    end
    column :email
    column :key_pair do |user|
      if(user.public_key.nil? or user.private_key.nil?)
        status_tag("Missing", :error)
      else
        status_tag("Present", :ok)
      end
    end
    default_actions
  end

  show do |user|
    attributes_table do
      row :name
      row :email
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
      f.input :email
      f.input :name
      unless f.object.persisted?
        f.input :password
        f.input :password_confirmation, :required => true
      end
      f.form_buffers.last # https://github.com/gregbell/active_admin/pull/965
    end

    f.buttons
  end

  member_action :download_public_key do
    @user = User.find(params[:id])
    
    send_data @user.public_key, :filename => "#{@user.email}.pub" unless @user.public_key.nil?
  end
  member_action :download_private_key do
    @user = User.find(params[:id])
    
    send_data @user.private_key, :filename => "#{@user.email}.key" unless @user.private_key.nil?
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
    link_to 'Generate new keypair', generate_keypair_form_admin_user_path(resource)
  end
end
