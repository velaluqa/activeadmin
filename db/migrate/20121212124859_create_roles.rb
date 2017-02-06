class CreateRoles < ActiveRecord::Migration
  def change
    create_table :roles do |t|
      t.references :object, :polymorphic => true
      t.references :user
      t.integer :role

      t.timestamps :null => true
    end
  end
end
