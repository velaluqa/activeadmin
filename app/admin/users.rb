ActiveAdmin.register User do
  menu(
    parent: 'users',
    priority: 10,
    if: -> { current_user.is_root_user? || User.accessible_by(current_ability, :read).count > 1 }
  )

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
    column :name, sortable: :name do |user|
      link_to user.name, admin_user_path(user)
    end
    column :username
    column :email do |user|
      user.email || '-'
    end
    column :key_pair do |user|
      if user.public_key.nil? || user.private_key.nil?
        status_tag('Missing', class: 'error')
      else
        status_tag('Present', class: 'ok')
      end
    end
    column :locked do |user|
      if user.access_locked?
        status_tag('Locked', class: 'error')
      else
        status_tag('Unlocked', class: 'ok')
      end
    end
    column :confirmed do |user|
      if user.confirmed?
        status_tag("Confirmed at #{pretty_format(user.confirmed_at)}", class: 'ok')
      else
        status_tag('Unconfirmed', class: 'error')
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
        if user.current_sign_in_at.nil?
          'No'
        else
          "Yes, since #{pretty_format(user.current_sign_in_at)} from #{user.current_sign_in_ip}"
        end
      end
      row :last_sign_in do
        if user.last_sign_in_at.nil?
          'Never'
        else
          "#{pretty_format(user.last_sign_in_at)} from #{user.last_sign_in_ip}"
        end
      end
      row :failed_attempts
      row :locked do
        if user.access_locked?
          status_tag("Locked at #{pretty_format(user.locked_at)}", class: 'error')
        else
          status_tag('Unlocked', class: 'ok')
        end
      end
      row :confirmed do
        if user.confirmed?
          status_tag("Confirmed at #{pretty_format(user.confirmed_at)}", class: 'ok')
        else
          status_tag('Unconfirmed', class: 'error')
        end
      end
      row :public_key do
        if user.public_key.nil?
          status_tag('Missing', class: 'error')
        else
          link_to 'Download Public Key', download_public_key_admin_user_path(user)
        end
      end
      row 'Past public keys' do
        link_to(user.public_keys.count, admin_public_keys_path(:'q[user_id_eq]' => user.id))
      end
      row :private_key do
        if user.private_key.nil?
          status_tag('Missing', class: 'error')
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
        input :password, required: object.new_record?
        input :password_confirmation
      end
    end
    if object.new_record?
      inputs 'Signature Password' do
        para 'If you do not set a signature password for a new user, the user will be asked to specify a password upon first login to the ERICA system.'
        input :signature_password
        input :signature_password_confirmation
      end
    end
    inputs 'Settings' do
      input :email_throttling_delay, as: :select, collection: Email.allowed_throttling_delays, input_html: { class: 'initialize-select2' }
    end
    if f.object != current_user && can?(%i[create update destroy], UserRole)
      inputs 'Roles' do
        has_many :user_roles, allow_destroy: true do |ur|
          collection = [['*system-wide*', 'systemwide']]
          unless ur.object.scope_object_identifier == 'systemwide'
            collection.push([ur.object.scope_object.to_s, ur.object.scope_object_identifier])
          end

          ur.input :role, collection: Role.order('title'), input_html: { class: 'initialize-select2' }
          ur.input(
            :scope_object_identifier,
            collection: collection,
            input_html: {
              class: 'select2-record-search',
              'data-models' => 'Study,Center,Patient',
              'data-placeholder' => '*system-wide*',
              'data-clear-value' => 'systemwide',
              'data-allow-clear' => true
            }
          )
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

    send_data @user.public_key, filename: "#{@user.username}.pub" unless @user.public_key.nil?
  end
  member_action :download_private_key do
    @user = User.find(params[:id])

    send_data @user.private_key, filename: "#{@user.username}.key" unless @user.private_key.nil?
  end

  member_action :generate_keypair, method: :post do
    if params[:user][:password].nil? || params[:user][:password].empty?
      flash[:error] = 'You must supply a password for the private key'
      redirect_to action: :show
      return
    end

    @user = User.find(params[:id])
    @user.generate_keypair(params[:user][:password])

    redirect_to({ action: :show }, notice: 'New keypair successfully generated')
  end
  member_action :generate_keypair_form, method: :get do
    @user = User.find(params[:id])

    @page_title = 'Generate new keypair'
    render 'admin/users/generate_keypair'
  end

  action_item :generate_keypair, only: :show do
    link_to 'Generate new keypair', generate_keypair_form_admin_user_path(resource), confirm: 'Generating a new keypair will disable the old signature of this user. Are you sure you want to do this?' if can? :generate_keypair, resource
  end

  member_action :unlock, method: :get do
    authorize!(:lock, resource)

    resource.unlock_access! if resource.access_locked?
    redirect_to({ action: :show }, notice: 'User unlocked!')
  end

  action_item :unlock, only: :show, if: -> { can?(:manage, User) && resource.access_locked? } do
    link_to 'Unlock', unlock_admin_user_path(resource)
  end

  action_item :audit_trail, only: :show, if: -> { can?(:read, Version) } do
    url = admin_versions_path(
      audit_trail_view_type: 'user',
      audit_trail_view_id: resource.id
    )
    link_to('Audit Trail', url)
  end
end
