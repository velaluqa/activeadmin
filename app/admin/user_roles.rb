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
      f.input :role
      f.input :scope_object_identifier, collection: UserRole.accessible_scope_object_identifiers(current_ability)
    end
    f.actions
  end
end
