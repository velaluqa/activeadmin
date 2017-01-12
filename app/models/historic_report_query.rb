# coding: utf-8
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
      next if delta.nil?
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
    count = { total: ungrouped_count(study_id) }
    count[:group] = grouped_count(study_id) unless group_by.blank?
    count
  end

  def ungrouped_count(study_id)
    if resource_class.respond_to?(:count_for_study)
      return resource_class.count_for_study(study_id)
    end
    resource_class.join_study.where(studies: { id: study_id }).count
  end

  def grouped_count(study_id)
    if resource_class.respond_to?(:grouped_count_for_study)
      return resource_class.grouped_count_for_study(study_id, group_by)
    end
    resource_class
      .join_study
      .where(studies: { id: study_id })
      .group("\"#{resource_class.table_name}\".\"#{group_by}\"")
      .count
      .stringify_keys
  end

  def entry_values(count, delta)
    count = count.with_indifferent_access
    delta = delta.with_indifferent_access
    values = []
    values.push(group: nil, count: count[:total], delta: delta[:total]) unless delta[:total] == 0
    count_keys = count[:group].andand.keys || []
    delta_keys = delta[:group].andand.keys || []
    (count_keys + delta_keys)
      .uniq
      .each do |group|
      group_count = count[:group].andand[group] || 0
      group_delta = delta[:group].andand[group] || 0
      next if group_delta == 0
      values.push(group: group, count: group_count, delta: group_delta)
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
        count[:group][key] ||= 0
        count[:group][key] -= delta_val
      else
        count[:group][key] ||= 0
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
      group = version.object_changes[group_by].andand[1] || resource_class.column_defaults[group_by]
      {
        total: +1,
        group: {
          group.to_s => +1
        }
      }
    when 'destroy' then
      {
        total: -1,
        group: {
          version.object[group_by].to_s => -1
        }
      }
    when 'update' then
      return nil unless version.object_changes.key?(group_by)
      {
        total: 0,
        group: {
          version.object_changes[group_by][0].to_s => -1,
          version.object_changes[group_by][1].to_s => +1
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
