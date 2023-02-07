module Migration
  ASSOCS = {
    "Image" => [
      {
        type: "ImageSeries",
        getter: :image_series,
        setter: :image_series=,
        foreign_key: :image_series_id
      }
    ],
    "Visit" => [
      {
        type: "Patient",
        getter: :patient,
        setter: :patient=,
        foreign_key: :patient_id
      }
    ],
    "Patient" => [
      {
        type: "Center",
        getter: :center,
        setter: :center=,
        foreign_key: :center_id
      }
    ],
    "NotificationProfileUser" => [
      {
        type: "User",
        getter: :user,
        setter: :user=,
        foreign_key: :user_id
      }
    ],
    "NotificationProfileRole" => [
      {
        type: "Role",
        getter: :role,
        setter: :role=,
        foreign_key: :role_id
      }
    ],
    "FormAnswer" => [
      {
        type: "FormDefinition",
        getter: :form_definition,
        setter: :form_definition=,
        foreign_key: :form_definition_id
      }
    ],
    "Configuration" => [
      {
        type: :configurable_type,
        getter: :configurable,
        setter: :configurable=,
        foreign_key: :configurable_id
      }
    ],
    "RequiredSeries" => [
      {
        type: "Visit",
        getter: :visit,
        setter: :visit=,
        foreign_key: :visit_id
      }
    ],
    "UserRole" => [
      {
        type: "Role",
        getter: :role,
        setter: :role=,
        foreign_key: :role_id
      }
    ],
    "Permission" => [
      {
        type: "Role",
        getter: :role,
        setter: :role=,
        foreign_key: :role_id
      }
    ]
  }

  class AddMissingVersionItemName
    class << self
      def run
        versions = Version.all
        count = versions.count
        versions.find_each.with_index do |v, i|
          puts "#{i} / #{count} - Migrating for #{v.item_type} version ..."
          item = v.item ||
            if v.event == "create"
              v.next.reify
            else
              v.reify
            end
          restore_associations(v.item_type, item)
          v.item_name = item.versions_item_name
          v.save!
        end
      end

      def restore_associations(root_type, item)
        assocs = ASSOCS[root_type]
        return if assocs.nil? || assocs.empty?

        assocs.each do |conf|
          next if item.send(conf[:getter])

          item_type =
            if conf[:type].is_a?(Symbol)
              item.send(conf[:type])
            else
              conf[:type]
            end
          reified_item = Version.where(
            item_type: item_type,
            item_id: item.send(conf[:foreign_key])
          ).last.reify

          restore_associations(item_type, reified_item)

          item.send(conf[:setter], reified_item)
        end
      end
    end
  end
end

