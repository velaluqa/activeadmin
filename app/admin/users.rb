ActiveAdmin.register User do
  menu if: proc { can? :read, User }

  config.comments = false

  controller do
    def max_csv_records
      1_000_000
    end


    def scoped_collection
      end_of_association_chain.distinct
    end
  end

  index do
    selectable_column
    column :name, :sortable => :name do |user|
      link_to user.name, admin_user_path(user)
    end
    column :username
    column :email do |user|
      user.email || '-'
    end
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
    column :confirmed do |user|
      if user.confirmed?
        status_tag("Confirmed at #{pretty_format(user.confirmed_at)}", :ok)
      else
        status_tag('Unconfirmed', :error)
      end
    end
    column 'Roles' do |user|
      link_to "#{user.user_roles.count} Roles", admin_user_user_roles_path(user_id: user.id)
    end
    customizable_default_actions(current_ability)
  end

  show do |user|
    attributes_table do
      row :name
      row :username
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
      row :failed_attempts
      row :locked do
        if(user.access_locked?)
          status_tag("Locked at #{pretty_format(user.locked_at)}", :error)
        else
          status_tag('Unlocked', :ok)
        end
      end
      row :confirmed do
        if user.confirmed?
          status_tag("Confirmed at #{pretty_format(user.confirmed_at)}", :ok)
        else
          status_tag('Unconfirmed', :error)
        end
      end
      row :public_key do
        if user.public_key.nil?
          status_tag("Missing", :error)
        else
          link_to 'Download Public Key', download_public_key_admin_user_path(user)
        end
      end
      row 'Past public keys' do
        link_to(user.public_keys.count, admin_public_keys_path(:'q[user_id_eq]' => user.id))
      end
      row :private_key do
        if user.private_key.nil?
          status_tag("Missing", :error)
        else
          link_to 'Download Private Key', download_private_key_admin_user_path(user)
        end
      end
      row 'Roles' do |user|
        link_to "#{user.user_roles.count} Roles", admin_user_user_roles_path(user_id: user.id)
      end
    end
  end

  form do |f|
    inputs 'User Information' do
      input :username
      input :name
      input :email
      if object.new_record? || can?(:change_password, object)
        input :password, :required => object.new_record?
        input :password_confirmation
      end
      if object.new_record?
        input :signature_password, :required => true
        input :signature_password_confirmation
      end
    end
    inputs 'Settings' do
      input :email_throttling_delay, as: :select, collection: Email.allowed_throttling_delays, input_html: { class: 'initialize-select2' }
    end
    if f.object != current_user && can?(%i(create update destroy), UserRole)
      inputs 'Roles' do
        has_many :user_roles, allow_destroy: true do |ur|
          ur.input :role
          ur.input :scope_object_identifier, collection: [['*system-wide*', 'systemwide']] + UserRole.accessible_scope_object_identifiers(current_ability)
        end
      end
    end
    actions
  end

  # filters
  filter :username
  filter :name
  filter :roles

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

  action_item :edit, :only => :show do
    link_to 'Generate new keypair', generate_keypair_form_admin_user_path(resource), :confirm => 'Generating a new keypair will disable the old signature of this user. Are you sure you want to do this?' if can? :manage, resource
  end

  member_action :unlock, :method => :get do
    authorize!(:lock, resource)

    resource.unlock_access! if resource.access_locked?
    redirect_to({:action => :show}, :notice => 'User unlocked!')
  end

  action_item :edit, :only => :show do
    link_to 'Unlock', unlock_admin_user_path(resource) if(can? :manage, :system and resource.access_locked?)
  end

  action_item :edit, :only => :show do
    link_to('Audit Trail', admin_versions_path(:audit_trail_view_type => 'user', :audit_trail_view_id => resource.id)) if can? :read, Version
  end
end
