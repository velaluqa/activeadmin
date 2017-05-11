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
      'day week month quarter year'.include?(@resolution)
    end

    def historic_query
      date_trunc = "date_trunc('#{@resolution}', entries.\"date\")#{date_resolution? ? '::date' : ''}"
      if @group_by.blank?
        return <<QUERY.strip_heredoc
          SELECT
            DISTINCT ON (#{date_trunc})
            #{date_trunc} AS date,
            values."group" AS "group",
            values.count AS max
          FROM
            historic_report_cache_entries entries,
            historic_report_cache_values values
          WHERE
            values.historic_report_cache_entry_id = entries.id AND
            entries.historic_report_query_id = #{@query.id} AND
            entries.study_id = #{@study_id}
          ORDER BY #{date_trunc}, entries.date DESC;
QUERY
      end
      <<QUERY.strip_heredoc
        WITH
          groups AS (
            SELECT DISTINCT _hcv."group"
            FROM
              historic_report_cache_entries _hce,
              historic_report_cache_values _hcv
            WHERE
              _hce.id = _hcv.historic_report_cache_entry_id AND
              _hce.historic_report_query_id = #{@query.id} AND
              _hcv."group" IS NOT NULL
          ),
          date_anchor AS (
            SELECT * FROM (VALUES ('2000-01-01 00:00:00'::timestamp, 0::integer)) AS anchor(date, value)
          ),
          values AS (
            SELECT
              _hce.date,
              _hcv.group,
              _hcv.count
            FROM
              historic_report_cache_entries _hce,
              historic_report_cache_values _hcv
            WHERE
              _hce.id = _hcv.historic_report_cache_entry_id AND
              _hce.historic_report_query_id = #{@query.id} AND
              _hce.study_id = #{@study_id}

            UNION

            SELECT date, "group", value FROM groups, date_anchor
          )
        SELECT
          DISTINCT ON (#{date_trunc}, groups."group")
          #{date_trunc} AS date,
          groups."group" AS group,
          values.count AS max
        FROM historic_report_cache_entries entries
        CROSS JOIN groups
        INNER JOIN values ON values."group" = groups."group"
        WHERE
          entries.historic_report_query_id = #{@query.id} AND
          entries.study_id = #{@study_id} AND
          values.date <= entries.date
        ORDER BY #{date_trunc}, groups."group", values.date DESC;
QUERY
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
