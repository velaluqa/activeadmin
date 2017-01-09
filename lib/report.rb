require 'report/overview'

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
      Visit => { 'state' => Visit::STATE_SYMS }
    }
  end
end
