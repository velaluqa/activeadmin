ActiveAdmin.register NotificationProfile do
  config.filters = false

  config.per_page = 100

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
      f.input :triggering_action, as: :select, collection: %w(all create update destroy)
      f.input :triggering_resource, as: :select, collection: NotificationObservable.resources.map(&:to_s).sort.uniq
    end

    f.inputs 'Filters', class: 'filters' do
      f.render partial: 'filters_json_editor'
    end

    f.inputs 'Recipients' do
      f.input :roles, multiple: true, as: :select, collection: Role.all
      f.input :users, multiple: true, as: :select, collection: User.all
      f.input :only_authorized_recipients
      f.input :maximum_email_throttling_delay, as: :select, collection: Email::THROTTLING_DELAYS.keys
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
