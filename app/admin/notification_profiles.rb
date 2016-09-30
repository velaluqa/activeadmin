ActiveAdmin.register NotificationProfile do
  config.filters = false

  config.per_page = 100

  permit_params :title, :description, :is_active, :triggering_action,
                :triggering_resource, :filters_json, :only_authorized_recipients,
                :maximum_email_throttling_delay, user_ids: [], role_ids: []

  controller do
    def max_csv_records
      1_000_000
    end
  end

  index do
    selectable_column
    column :title
    column :recipients do |profile|
      "#{profile.recipients.count} recipients"
    end
    customizable_default_actions(current_ability)
  end

  show do |profile|
    attributes_table do
      row :id
      row :title
      column :recipients do
        "#{profile.recipients.count} recipients"
      end
    end
  end

  form do |f|
    f.inputs 'Details' do
      f.input :title
      f.input :description
      f.input :is_active
    end

    f.inputs 'Triggers' do
      f.input :triggering_action, as: :select, collection: %w(all create update destroy), input_html: { class: 'initialize-select2' }
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
      f.input :maximum_email_throttling_delay, as: :select, collection: Email.allowed_throttling_delays
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
