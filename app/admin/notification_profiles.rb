ActiveAdmin.register NotificationProfile do
  menu(
    parent: 'notifications',
    priority: 10
  )

  config.filters = false

  config.per_page = 100

  permit_params(
    :title,
    :description,
    :is_enabled,
    :triggering_resource,
    :filters_json,
    :only_authorized_recipients,
    :filter_triggering_user,
    :maximum_email_throttling_delay,
    :email_template_id,
    triggering_actions: [],
    recipient_refs: []
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
      if profile.is_enabled
        status_tag('Enabled', class: 'ok')
      else
        status_tag('Disabled', class: 'error')
      end
    end
    column :triggering_actions do |profile|
      profile.triggering_actions.join(', ')
    end
    column :triggering_resource
    customizable_default_actions(current_ability)
  end

  show do |profile|
    attributes_table do
      row :title
      row :description
      row :is_enabled
      row :email_template do
        profile.email_template.name
      end
      row :maximum_email_throttling_delay do
        delay = Email::THROTTLING_DELAYS.key(profile.maximum_email_throttling_delay)
        status_tag(delay, class: 'note')
      end
    end

    panel 'Triggering Settings' do
      attributes_table_for profile do
        row :triggering_actions do
          profile.triggering_actions.each do |action|
            case action
            when 'create' then status_tag(action, class: 'ok')
            when 'update' then status_tag(action, class: 'warning')
            when 'destroy' then status_tag(action, class: 'error')
            end
          end
          ""
        end
        row :triggering_resource
        row :filters do
          profile.filter.to_s
        end
      end
    end

    panel 'Recipients' do
      attributes_table_for profile do
        row :users do
          if profile.all_users?
            "All users"
          else
            profile.users
              .map { |user| link_to(user.username, admin_url_for(user)) }
              .join(', ')
              .html_safe
          end
        end
        row :roles do
          if profile.all_users?
            "All roles"
          else
            profile.roles
              .map { |role| link_to(role.title, admin_url_for(role)) }
              .join(', ')
              .html_safe
          end
        end
        row :filter_triggering_user do
          t("model.notification_profile.filter_triggering_user.#{profile.filter_triggering_user}")
        end
        row :only_authorized_recipients
      end
    end
  end

  form do |f|
    f.object.maximum_email_throttling_delay ||= ERICA.maximum_email_throttling_delay

    f.inputs 'Details' do
      f.input :title
      f.input :description
      f.input :is_enabled
    end

    f.inputs 'Triggers' do
      f.input :triggering_actions, as: :select, multiple: true, collection: %w(create update destroy), input_html: { class: 'initialize-select2', 'data-placeholder': 'Select triggering actions' }
      f.input :triggering_resource, as: :select, collection: NotificationProfile::TRIGGERING_RESOURCES, input_html: { class: 'initialize-select2', 'data-placeholder': 'Select triggering resource' }
    end

    f.inputs 'Filters', class: 'filters' do
      f.input :filters_json, as: :hidden
      f.render partial: 'filters_json_editor'
    end

    f.inputs 'Recipients' do
      f.input(
        :recipient_refs,
        label: 'Recipients',
        type: :select,
        multiple: true,
        collection: f.object.preload_recipient_refs,
        input_html: {
          class: 'select2-record-search',
          'data-models' => 'User,Role',
          'data-placeholder' => 'All Users',
          'data-clear-value' => 'all',
          'data-template-prepend-type' => true,
          'data-allow-clear' => true
        }
      )

      f.input(
        :filter_triggering_user,
        as: :select,
        collection: ['exclude', 'include', 'only'].map do |value|
          [t("model.notification_profile.filter_triggering_user.#{value}"), value]
        end,
        input_html: {
          class: 'initialize-select2',
          'data-placeholder' => 'Choose filter for triggering user'
        }
      )
      f.input :only_authorized_recipients
      f.input :maximum_email_throttling_delay, as: :select, collection: Email.allowed_throttling_delays, input_html: { class: 'initialize-select2', 'data-placeholder': 'Select maximum email throttling delay' }
      f.input :email_template_id, as: :select, collection: EmailTemplate.where(email_type: 'NotificationProfile'), input_html: { class: 'initialize-select2', 'data-placeholder': 'Select template' }
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
