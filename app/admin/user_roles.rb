ActiveAdmin.register UserRole do
  belongs_to :user

  menu false
  navigation_menu false
  config.batch_actions = false

  actions :index, :new, :create, :edit, :update, :destroy

  filter :scope_object, collection: -> { UserRole.accessible_scope_object_identifiers(current_ability) }
  filter :role
  filter :permissions

  index do
    column :role
    column 'Scope' do |user_role|
      if user_role.scope_object.nil?
        'system-wide'
      else
        link_to user_role.scope_object
      end
    end
    customizable_default_actions(current_ability)
  end

  form do |f|
    f.inputs do
      collection = [['*system-wide*', 'systemwide']]
      unless f.object.scope_object_identifier == 'systemwide'
        collection.push([f.object.scope_object.to_s, f.object.scope_object_identifier])
      end

      f.input :role, collection: Role.order('title'), input_html: { class: 'initialize-select2' }
      f.input(
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
    f.actions
  end
end
