class MigrateFormDefinitionConfigurationLayoutNestings < ActiveRecord::Migration[5.2]
  def change
    Configuration.where(schema_spec: "formio_v1").each do |configuration|
      data = configuration.data
      if !data.key?("layout")
        puts "Migrating configuration layout into nested field for #{configuration.payload}"
        configuration.data = {
          "layout" => data
        }
        configuration.save!
      end
    end
  end
end
