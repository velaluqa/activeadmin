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

  def calculate_cache_async(study_id)
    HistoricReportCacheWorker.perform_async(id, study_id)
  end

  def calculate_cache(study_id)
    current_count = current_count(study_id)
    versions = Version
               .where('"versions"."id" <= ?', Version.last.id)
               .of_study_resource(study_id, resource_type)
               .order('"versions"."id" DESC')
    versions.ordered_find_each do |version|
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
    return calculate_rs_delta(version) if resource_type == 'RequiredSeries'
    if group_by.blank?
      calculate_ungrouped_delta(version)
    else
      calculate_grouped_delta(version)
    end
  end

  # TODO: Refactor in the process of moving required_series
  # associations out of a JSON field into single relations.
  #
  # Apologies to anyone who has to maintain this stuff.
  # Deadline is pressing.
  def calculate_rs_delta(version)
    if group_by.blank?
      calculate_ungrouped_rs_delta(version)
    else
      calculate_grouped_rs_delta(version)
    end
  end

  def calculate_grouped_rs_delta(version)
    changed = false
    delta = {
      total: 0,
      group: {}
    }
    case version.event
    when 'create'
      rs = version.object_changes['required_series'].andand[1] || {}
      rs.each_pair do |_, data|
        next if data['image_series_id'].nil?
        changed = true
        delta[:total] += 1
        delta[:group][data[group_by].to_s] ||= 0
        delta[:group][data[group_by].to_s] += 1
      end
    when 'destroy' then
      rs = version.object['required_series'] || {}
      rs.each_pair do |_, data|
        next if data['image_series_id'].nil?
        changed = true
        delta[:total] -= 1
        delta[:group][data[group_by].to_s] ||= 0
        delta[:group][data[group_by].to_s] -= 1
      end
    when 'update'
      old, new = version.object_changes['required_series']
      old_count = { total: 0, group: {} }
      (old || {}).each_pair do |_, data|
        next if data['image_series_id'].nil?
        old_count[:total] += 1
        old_count[:group][data[group_by].to_s] ||= 0
        old_count[:group][data[group_by].to_s] += 1
      end

      new_count = { total: 0, group: {} }
      (new || {}).each_pair do |_, data|
        next if data['image_series_id'].nil?
        new_count[:total] += 1
        new_count[:group][data[group_by].to_s] ||= 0
        new_count[:group][data[group_by].to_s] += 1
      end
      changed = true if new_count[:total] != old_count[:total]
      delta = {
        total: new_count[:total] - old_count[:total],
        group: (old_count[:group].keys + new_count[:group].keys)
              .uniq
              .map do |group|
                 old_group_count = old_count[:group][group] || 0
                 new_group_count = new_count[:group][group] || 0
                 changed = true if old_group_count != new_group_count
                 [
                   group.to_s,
                   new_group_count - old_group_count
                 ]
               end.to_h
      }
    end
    delta if changed
  end

  def calculate_ungrouped_rs_delta(version)
    case version.event
    when 'create'
      delta = 0
      rs = version.object_changes['required_series'].andand[1] || {}
      rs.each_pair do |_, data|
        delta += 1 if data['image_series_id']
      end
      { total: delta } if delta != 0
    when 'destroy' then
      delta = 0
      rs = version.object['required_series'] || {}
      rs.each_pair do |_, data|
        delta -= 1 if data['image_series_id']
      end
      { total: delta } if delta != 0
    when 'update'
      old, new = version.object_changes['required_series']
      old_count = 0
      (old || {}).each_pair do |_, data|
        old_count += 1 if data['image_series_id']
      end
      new_count = 0
      (new || {}).each_pair do |_, data|
        new_count += 1 if data['image_series_id']
      end
      delta = new_count - old_count
      { total: delta } if delta != 0
    end
  end
end
