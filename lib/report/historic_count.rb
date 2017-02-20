require 'report'

module Report
  # Gathers the count values in the requested respolution.
  class HistoricCount
    def initialize(options)
      @study_id = options[:study_id]

      @resource_type = options[:resource_type]
      @group_by = options[:group_by].blank? ? nil : options[:group_by]

      @start_at = options[:starts_at]
      @end_at = options[:ends_at]
      @resolution = options[:resolution] # day, week, month, quarter, year

      @query =
        HistoricReportQuery
          .where(resource_type: @resource_type, group_by: @group_by)
          .first_or_create

      @user = options[:user]
    end

    def study
      Study.find(@study_id)
    end

    def result
      @query.calculate_cache_async(@study_id)
      {
        title: "#{@resource_type.titlecase} history for #{study.name}",
        datasets: grouped_cache_result.map do |group, entries|
          transform_group(group, entries)
        end
      }
    end

    private

    def authorized?
      return true unless @user
      Study
        .where(id: @study_id)
        .granted_for(activity: :read_reports, user: @user)
        .exists?
    end

    def date_resolution?
      %q(day week month quarter year).include?(@resolution)
    end

    def historic_query
      rel =
        @query.cache_entries
          .joins(:historic_report_cache_values)
          .where(study_id: @study_id)
      if @group_by.blank?
        rel = rel.where('"historic_report_cache_values"."group" IS NULL')
      else
        rel = rel.where('"historic_report_cache_values"."group" IS NOT NULL')
      end
      rel.group(<<GROUP)
date_trunc('#{@resolution}', "historic_report_cache_entries"."date")#{date_resolution? ? '::date' : ''},
"historic_report_cache_values"."group"
GROUP
        .select(<<SELECT)
date_trunc('#{@resolution}', "historic_report_cache_entries"."date")#{date_resolution? ? '::date' : ''} AS date,
"historic_report_cache_values"."group" AS group,
MAX("historic_report_cache_values"."count") AS max
SELECT
        .order('date')
        .to_sql
    end

    def grouped_cache_result
      return {} unless authorized?
      res = ActiveRecord::Base.connection.execute(historic_query)
      res.group_by { |set| set['group'] }
    end

    def transform_entry(entry)
      {
        x: entry['date'],
        y: entry['max'].to_i
      }
    end

    def transform_group(group, entries)
      label =
        if @group_by.blank?
          'total'
        else
          Report.map_group_label(resource_class, @group_by, group)
        end
      {
        label: label,
        data: entries.map(&method(:transform_entry))
      }
    end

    def resource_class
      @resource_type.constantize
    end
  end
end
