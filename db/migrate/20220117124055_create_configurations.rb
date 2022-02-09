# Configuration
class CreateConfigurations < ActiveRecord::Migration[5.2]
  def change
    enable_extension 'pgcrypto' unless extension_enabled?('pgcrypto')
    create_enum :configuration_schema_specs, %w[formio_v1]

    create_table :configurations, id: :uuid, default: 'gen_random_uuid()'  do |t|
      t.uuid :previous_configuration_id, null: true, index: true
      t.text :payload, null: false
      t.string :configurable_type, null: false
      t.uuid :configurable_id, null: false, index: true
      t.enum :schema_spec, enum_type: :configuration_schema_specs, null: false, comment: <<~COMMENT
        Specify the configuration schema for the given `configuration_type`.
      COMMENT
      t.timestamps
    end
  end
end
