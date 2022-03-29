class CreateFormDefinitions < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')

    create_table :form_definitions, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.string :name, null: false
      t.text :description, null: false
      t.uuid :locked_configuration_id
      t.datetime :locked_at
      t.uuid :current_configuration_id

      t.timestamps
    end
  end
end
