dcm2xml = Rails.application.config.dcm2xml
unless File.exist?(dcm2xml)
  raise "config.dcm2xml = #{dcm2xml.inspect} not found"
end
dcmconv = Rails.application.config.dcmconv
unless File.exist?(dcmconv)
  raise "config.dcmconv = #{dcmconv.inspect} not found"
end
dcmj2pnm = Rails.application.config.dcmj2pnm
unless File.exist?(dcmj2pnm)
  raise "config.dcmj2pnm = #{dcmj2pnm.inspect} not found"
end
