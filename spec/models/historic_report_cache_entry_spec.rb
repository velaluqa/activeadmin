RSpec.describe HistoricReportCacheEntry do
  it { should belong_to(:historic_report_query) }
  it { should belong_to(:study) }
end
