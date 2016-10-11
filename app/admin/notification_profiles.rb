ActiveAdmin.register NotificationProfile do
  config.filters = false

  config.per_page = 100

  permit_params(
    :title,
    :description,
    :is_enabled,
    :triggering_resource,
    :filters_json,
    :only_authorized_recipients,
    :maximum_email_throttling_delay,
    triggering_actions: [],
    user_ids: [],
    role_ids: []
  )

  controller do
    def max_csv_records
      1_000_000
    end
  end

  index do
    selectable_column
    column :title
    column :is_enabled do |profile|
      profile.is_enabled ? 'enabled' : ''
    end
    column :triggering_actions do
      profile.triggering_actions.join(', ')
    end
    column :triggering_resource
    customizable_default_actions(current_ability)
  end

  show do |profile|
    attributes_table do
      row :id
      row :title
      row :description
      row :is_enabled do
        profile.is_enabled ? 'enabled' : ''
      end
      row :triggering_actions do
        profile.triggering_actions.join(', ')
      end
      row :triggering_resource
      row :filters do
        profile.filter.to_s
      end
      row :users do
        profile.users
          .map { |user| link_to(user.username, admin_url_for(user)) }
          .join(', ')
          .html_safe
      end
      row :roles do
        profile.roles
          .map { |role| link_to(role.title, admin_url_for(role)) }
          .join(', ')
          .html_safe
      end
      row :only_authorized_recipients
      row :maximum_email_throttling_delay do
        Email::THROTTLING_DELAYS.key(profile.maximum_email_throttling_delay)
      end
    end
  end

  form do |f|
    f.inputs 'Details' do
      f.input :title
      f.input :description
      f.input :is_enabled
    end

    f.inputs 'Triggers' do
      f.input :triggering_actions, as: :select, multiple: true, collection: %w(create update destroy), input_html: { class: 'initialize-select2' }
      f.input :triggering_resource, as: :select, collection: NotificationObservable.resources.map(&:to_s).sort.uniq, input_html: { class: 'initialize-select2' }
    end

    f.inputs 'Filters', class: 'filters' do
      f.input :filters_json, as: :hidden
      f.render partial: 'filters_json_editor'
    end

    f.inputs 'Recipients' do
      f.input :users, type: :select, multiple: true, collection: User.all, input_html: { class: 'initialize-select2' }
      f.input :roles, type: :select, multiple: true, collection: Role.all, input_html: { class: 'initialize-select2' }
      f.input :only_authorized_recipients
      f.input :maximum_email_throttling_delay, as: :select, collection: Email.allowed_throttling_delays, input_html: { class: 'initialize-select2' }
    end

    f.actions
  end

  collection_action :filters_schema, method: :get, format: :json do
    authorize! [:create, :update], NotificationProfile
    begin
      klass = params[:triggering_resource].constantize
      render json: NotificationObservable::Filter::Schema.new(klass).schema.to_json
    rescue => e
      render status: 500, json: { error: "Error generating filter schema for model #{params[:triggering_resource].inspect}: #{e}" }
    end
  end
end
