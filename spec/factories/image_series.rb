# ## Schema Information
#
# Table name: `image_series`
#
# ### Columns
#
# Name                      | Type               | Attributes
# ------------------------- | ------------------ | ---------------------------
# **`cache`**               | `jsonb`            | `not null`
# **`comment`**             | `string`           |
# **`created_at`**          | `datetime`         |
# **`domino_unid`**         | `string`           |
# **`id`**                  | `integer`          | `not null, primary key`
# **`imaging_date`**        | `date`             |
# **`name`**                | `string`           |
# **`patient_id`**          | `integer`          |
# **`properties`**          | `jsonb`            | `not null`
# **`properties_version`**  | `string`           |
# **`series_number`**       | `integer`          |
# **`state`**               | `integer`          | `default(0)`
# **`updated_at`**          | `datetime`         |
# **`visit_id`**            | `integer`          |
#
# ### Indexes
#
# * `index_image_series_on_patient_id`:
#     * **`patient_id`**
# * `index_image_series_on_patient_id_and_series_number`:
#     * **`patient_id`**
#     * **`series_number`**
# * `index_image_series_on_series_number`:
#     * **`series_number`**
# * `index_image_series_on_visit_id`:
#     * **`visit_id`**
#

FactoryBot.define do
  factory :image_series do
    transient do
      with_images { 0 }
    end

    sequence(:name) { |n| "image_series#{n}" }
    patient do |is|
      if is.visit
        is.visit.patient
      else
        create(:patient)
      end
    end
    imaging_date { Date.today }
    sequence(:series_number)
    sequence(:domino_unid) do |n|
      '00BEEAFBEC35CFF7C12578CC00517D20'[0..-n.to_s.length] + n.to_s
    end

    after(:create) do |image_series, context|
      1.upto(context.with_images) do |i|
        create(:image, image_series_id: image_series.id)
      end
    end
  end
end
