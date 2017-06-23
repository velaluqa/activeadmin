# ## Schema Information
#
# Table name: `versions`
#
# ### Columns
#
# Name                  | Type               | Attributes
# --------------------- | ------------------ | ---------------------------
# **`created_at`**      | `datetime`         |
# **`event`**           | `string`           | `not null`
# **`id`**              | `integer`          | `not null, primary key`
# **`item_id`**         | `integer`          | `not null`
# **`item_type`**       | `string`           | `not null`
# **`object`**          | `jsonb`            |
# **`object_changes`**  | `jsonb`            |
# **`study_id`**        | `integer`          |
# **`whodunnit`**       | `string`           |
#
# ### Indexes
#
# * `index_versions_on_item_type_and_item_id`:
#     * **`item_type`**
#     * **`item_id`**
#
class Version < PaperTrail::Version
  has_many :notifications

  attr_accessible(
    :created_at,
    :event,
    :item_type,
    :item_id,
    :object,
    :object_changes,
    :whodunnit,
    :study_id
  )

  belongs_to(:study)

  after_commit(:trigger_notification_profiles, on: :create)

  def triggering_user
    case whodunnit
    when User then whodunnit
    when String then User.find(whodunnit)
    end
  end

  def complete_changes
    if event == 'destroy'
      object.map do |key, val|
        [key, [val, nil]] unless val.nil?
      end.compact.to_h
    else
      object_changes
    end
  end

  # TODO: When updated to Ruby 2.4 use `Hash#transform_values`.
  def complete_attributes
    if event == 'destroy'
      object
    else
      (object || {}).merge(
        complete_changes.transform_values { |_, new| new }
      )
    end
  end

  private

  def trigger_notification_profiles
    TriggerNotificationProfiles.perform_async(id)
  end

  class << self
    # The provided method `find_each` of ActiveRecord is based on
    # `find_in_batches` which strips existing `order` filters and
    # orders by `id ASC` by default.
    #
    # This function keeps existing ordering intact.
    def ordered_find_each(&block)
      ids = all.pluck(:id)
      ids.in_groups_of(200) do |group_ids|
        all.where(id: group_ids).each(&block)
      end
    end

    # Scopes all versions for a given `study` and `item_type`.
    def of_study_resource(study, resource_type)
      study = Study.find(study) unless study.is_a?(Study)
      Version.where(item_type: resource_type, study_id: study.id)
    end

    def after(date, options = {})
      rel = where('"versions"."created_at" > ?', date)
      rel = rel.where(options) unless options.empty?
      rel.order('"versions"."id" ASC')
    end

    def before(date, options = {})
      rel = where('"versions"."created_at" < ?', date)
      rel = rel.where(options) unless options.empty?
      rel.order('"versions"."id" DESC')
    end
  end
end
