class CreateUserRoles < ActiveRecord::Migration
  def change
    create_table :user_roles do |t|
      t.belongs_to :user, null: false, index: true
      t.belongs_to :role, null: false, index: true
      t.references :scope_object, polymorphic: true, null: true, index: true
      t.timestamps null: false
    end
  end
end
