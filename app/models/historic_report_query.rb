# ## Schema Information
#
# Table name: `historic_report_queries`
#
# ### Columns
#
# Name                 | Type               | Attributes
# -------------------- | ------------------ | ---------------------------
# **`created_at`**     | `datetime`         | `not null`
# **`group_by`**       | `string`           |
# **`id`**             | `integer`          | `not null, primary key`
# **`resource_type`**  | `string`           |
# **`updated_at`**     | `datetime`         | `not null`
#
# Defines dashboard report queries for historic data.
#
# ERICA keeps all historic data in the audit trail. This data is
# extracted for reporting if available.
#
class HistoricReportQuery < ActiveRecord::Base
  has_many :historic_report_cache_entries
  alias_method :cache_entries, :historic_report_cache_entries

  def resource_class
    resource_type.constantize
  end

  def calculate_cache(study_id)
    current_count = current_count(study_id)
    versions = Version
                 .of_study_resource(study_id, resource_type)
                 .order('"versions"."created_at" DESC')
    versions.each do |version|
      delta = calculate_delta(version)
      HistoricReportCacheEntry.ensure_cache_entry(
        self,
        study_id,
        version.created_at,
        entry_values(current_count, delta)
      )
      current_count = apply_delta(current_count, delta, reverse: true)
    end
  end

  def current_count(study_id)
    count = {
      total: resource_class.join_study.where(studies: { id: study_id }).count,
      group: {}
    }
    if group_by
      count[:group] =
        resource_class.join_study
          .where(studies: { id: study_id })
          .group("\"#{resource_class.table_name}\".\"#{group_by}\"")
          .count
    end
    count
  end

  def entry_values(count, delta)
    values = [{ group: nil, count: count[:total], delta: delta[:total] }]
    (count[:group] || {}).each_pair do |key, val|
      values.push(group: key.to_s, count: val,  delta: delta[:group][key])
    end
    values
  end

  def apply_delta(count, delta, options = {})
    count = count.deep_dup
    delta.each_pair do |key, delta_val|
      next unless delta_val.is_a?(Fixnum)
      if options[:reverse]
        count[key] -= delta_val
      else
        count[key] += delta_val
      end
    end
    (delta[:group] || {}).each_pair do |key, delta_val|
      next unless delta_val.is_a?(Fixnum)
      if options[:reverse]
        count[:group][key] -= delta_val
      else
        count[:group][key] += delta_val
      end
    end
    count
  end

  def calculate_ungrouped_delta(version)
    case version.event
    when 'create' then { total: +1 }
    when 'destroy' then { total: -1 }
    when 'update' then nil
    end
  end

  def calculate_grouped_delta(version)
    case version.event
    when 'create' then
      {
        total: +1,
        group: {
          version.object_changes[group_by].andand[1] => +1
        }
      }
    when 'destroy' then
      {
        total: -1,
        group: {
          version.object[group_by] => -1
        }
      }
    when 'update' then
      return nil unless version.object_changes.key?(group_by)
      {
        total: 0,
        group: {
          version.object_changes[group_by][0] => -1,
          version.object_changes[group_by][1] => +1
        }
      }
    end
  end

  def calculate_delta(version)
    if group_by.blank?
      calculate_ungrouped_delta(version)
    else
      calculate_grouped_delta(version)
    end
  end
end
