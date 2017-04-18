require 'report/overview'
require 'report/historic_count'

module Report
  class UnknownReportType < StandardError; end

  def self.create(options)
    type = options[:type]
    params = options[:params].merge(user: options[:user])

    case type
    when 'overview' then Report::Overview.new(params)
    when 'historic_count' then Report::HistoricCount.new(params)
    else raise UnknownReportType, "Unknown type: #{type}"
    end
  end

  def self.mappings
    @mappings ||= {
      Visit => { 'state' => Visit::STATE_SYMS },
      ImageSeries => { 'state' => ImageSeries::STATE_SYMS }
    }
  end

  def self.map_group_label(resource_class, column, value)
    mapping = mappings[resource_class].andand[column]
    case mapping
    when Array then mapping[value.to_i]
    when Hash then mapping[value.to_sym]
    else value
    end
  rescue
    value
  end
end
