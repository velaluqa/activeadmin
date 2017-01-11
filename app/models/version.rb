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


  class << self
    # Scopes all versions for a given `study` and `item_type`.
    def of_study_resource(study, resource_type)
      study = Study.find(study) unless study.is_a?(Study)
      case resource_type
      when 'Patient' then patient_query(study)
      when 'Visit' then visit_query(study)
      when 'ImageSeries' then image_series_query(study)
      when 'RequiredSeries' then required_series_query(study)
      else Version.where(item_type: resource_type)
      end
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

    private

    def patient_query(study)
      Version
        .where(item_type: 'Patient')
        .where(<<QUERY)
   (object_changes -> 'center_id' ->> 1)::integer IN (#{study.centers.select(:id).to_sql})
OR (object ->> 'center_id')::integer IN (#{study.centers.select(:id).to_sql})
QUERY
    end

    def visit_query(study)
      Version
        .where(item_type: 'Visit')
        .where(<<QUERY)
   (object_changes -> 'patient_id' ->> 1)::integer IN (#{study.patients.select(:id).to_sql})
OR (object ->> 'patient_id')::integer IN (#{study.patients.select(:id).to_sql})
QUERY
    end

    def image_series_query(study)
      Version
        .where(item_type: 'ImageSeries')
        .where(<<QUERY)
   (object_changes -> 'patient_id' ->> 1)::integer IN (#{study.patients.select(:id).to_sql})
OR (object ->> 'patient_id')::integer IN (#{study.patients.select(:id).to_sql})
QUERY
    end

    def required_series_query(study)
      Version
        .where(item_type: 'Visit')
        .where(<<QUERY)
   (object_changes -> 'patient_id' ->> 1)::integer IN (#{study.patients.select(:id).to_sql})
OR (object ->> 'patient_id')::integer IN (#{study.patients.select(:id).to_sql})
QUERY
    end
  end
end
