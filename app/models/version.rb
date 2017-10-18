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

  scope :for_study, -> (study_id) { where(study_id: study_id) }
  # TODO: #3353 - Use Version#center_id: association_chain.where(center_id: params[:audit_trail_view_id])
  scope :for_center, -> (center_id) { where(<<WHERE.strip_heredoc, center_id: center_id) }
    (item_type LIKE 'Center' AND item_id = :center_id) OR
    (item_type LIKE 'Patient' AND item_id IN (SELECT id FROM patients WHERE patients.center_id = :center_id)) OR
    (item_type LIKE 'Visit' AND item_id IN
      (SELECT id FROM visits WHERE visits.patient_id IN
        (SELECT id FROM patients WHERE patients.center_id = :center_id))) OR
    (item_type LIKE 'ImageSeries' AND item_id IN
      (SELECT id FROM image_series WHERE image_series.patient_id IN
        (SELECT id FROM patients WHERE patients.center_id = :center_id))) OR
    (item_type LIKE 'Image' AND item_id IN
      (SELECT id FROM images WHERE images.image_series_id IN
        (SELECT id FROM image_series WHERE image_series.patient_id IN
          (SELECT id FROM patients WHERE patients.center_id = :center_id))))
WHERE
  # TODO: #3353 - Use Version#patient_id: association_chain.where(patient_id: params[:audit_trail_view_id])
  scope :for_patient, -> (patient_id) { where(<<WHERE.strip_heredoc, patient_id: patient_id) }
    (item_type LIKE 'Patient' AND item_id = :patient_id) OR
    (item_type LIKE 'Visit' AND item_id IN
      (SELECT id FROM visits WHERE visits.patient_id = :patient_id)) OR
    (item_type LIKE 'ImageSeries' AND item_id IN
      (SELECT id FROM image_series WHERE image_series.patient_id = :patient_id)) OR
    (item_type LIKE 'Image' AND item_id IN
      (SELECT id FROM images WHERE images.image_series_id IN
        (SELECT id FROM image_series WHERE image_series.patient_id = :patient_id)))
WHERE
  # TODO: #3353 - Use Version#visit_id: association_chain.where(visit_id: params[:audit_trail_view_id])
  scope :for_visit, -> (visit_id) { where(<<WHERE.strip_heredoc, visit_id: visit_id) }
    (item_type LIKE 'Visit' AND item_id = :visit_id) OR
    (item_type LIKE 'ImageSeries' AND item_id IN
      (SELECT id FROM image_series WHERE image_series.visit_id = :visit_id)) OR
    (item_type LIKE 'Image' AND item_id IN
      (SELECT id FROM images WHERE images.image_series_id IN
        (SELECT id FROM image_series WHERE image_series.visit_id = :visit_id)))
WHERE
  # TODO: #3353 - Use Version#image_series_id: association_chain.where(image_series_id: params[:audit_trail_view_id])
  scope :for_image_series, -> (image_series_id) { where(<<WHERE.strip_heredoc, image_series_id: image_series_id) }
    (item_type LIKE 'ImageSeries' AND item_id = :image_series_id) OR
    (item_type LIKE 'Image' AND item_id IN
      (SELECT id FROM images WHERE images.image_series_id = :image_series_id))
WHERE
  # TODO: #3353 - Use Version#image_series_id: association_chain.where(image_id: params[:audit_trail_view_id])
  scope :for_image, -> (image_id) { where('item_type LIKE \'Image\' AND item_id = ?', image_id) }
  scope :for_role, -> (image_id) { where('item_type LIKE \'Role\' AND item_id = ?', image_id) }
  scope :for_user, -> (user_id) { where(<<WHERE.strip_heredoc, user_id: user_id) }
    (item_type LIKE 'User' AND item_id = :user_id) OR
    (item_type LIKE 'UserRole' and item_id IN
      (SELECT id FROM user_roles WHERE user_roles.user_id = :user_id))
WHERE

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
