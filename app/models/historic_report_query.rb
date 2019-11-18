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
class HistoricReportQuery < ApplicationRecord
  has_many :historic_report_cache_entries
  alias_method :cache_entries, :historic_report_cache_entries

  def resource_class
    resource_type.constantize
  end

  def calculate_cache_async(study_id)
    HistoricReportCacheWorker.perform_async(id, study_id)
  end

  def calculate_cache(study_id)
    current_count = current_count(study_id)
    versions = Version
               .where('"versions"."id" <= ?', Version.last.id)
               .of_study_resource(study_id, resource_type)
               .order("versions.id" => :desc)
    versions.ordered_find_each do |version|
      delta = calculate_delta(version)
      next if delta.nil?
      HistoricReportCacheEntry.ensure_cache_entry(
        self,
        study_id,
        version,
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
    (count_keys + delta_keys).uniq.each do |group|
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
      next unless delta_val.is_a?(Integer)
      if options[:reverse]
        count[key] -= delta_val
      else
        count[key] += delta_val
      end
    end
    (delta[:group] || {}).each_pair do |key, delta_val|
      next unless delta_val.is_a?(Integer)
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

  def classify_event(version)
    case version.item_type
    when 'RequiredSeries' then classify_required_series_event(version)
    else classify_basic_event(version)
    end
  end

  def classify_basic_event(version)
    version.event
  end

  def classify_required_series_event(version)
    changes = version.complete_changes
    return if changes['image_series_id'].blank?
    was = changes['image_series_id'][0]
    becomes = changes['image_series_id'][1]
    if was.nil? && becomes.present? then 'create'
    elsif was.present? && becomes.nil? then 'destroy'
    else 'update'
    end
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
          map_group_name(group) => +1
        }
      }
    when 'destroy' then
      group = version.object[group_by]
      {
        total: -1,
        group: {
          map_group_name(group) => -1
        }
      }
    when 'update' then
      return nil unless version.object_changes.key?(group_by)
      old_group = version.object_changes[group_by][0]
      new_group = version.object_changes[group_by][1]
      {
        total: 0,
        group: {
          map_group_name(old_group) => -1,
          map_group_name(new_group) => +1
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

  def map_group_name(group)
    self.class.map_group_name(resource_type, group)
  end

  def self.map_group_name(resource_type, group)
    case resource_type
    when 'RequiredSeries' then
      return 'unassigned' if group.nil?
      return group if RequiredSeries.tqc_states.include?(group)
      return 'unassigned' if group.is_a?(String) && group.to_i.to_s != group
      RequiredSeries.tqc_states.key(group.to_i) || 'unassigned'
    else group.to_s
    end
  end
end
