class CreateFormSessions < ActiveRecord::Migration[5.2]
  def change
    create_table :form_sessions do |t|
      t.string :name, null: false, index: true
      t.string :description, null: true

      t.timestamps
    end
  end
end
