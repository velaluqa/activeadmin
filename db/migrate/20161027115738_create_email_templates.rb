class CreateEmailTemplates < ActiveRecord::Migration
  def change
    create_table :email_templates do |t|
      t.string :name, null: false
      t.string :email_type, null: false
      t.text :template, null: false
      t.timestamps null: false
    end
  end
end
