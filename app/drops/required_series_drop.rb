class RequiredSeriesDrop < EricaDrop # :nodoc:
  desc 'Returns the name of the required series.', 'String'
  attribute(:name)

  desc 'Returns the complete tQC results.', 'Hash<String, String>'
  attribute(:tqc_results)

  desc 'Returns tQC state.', 'String'
  def tqc_state
    object.tqc_state.to_s
  end

  desc 'Returns a list of failed checks.', 'Array<String>'
  def failed_tqc_checks
    (object.tqc_results || {}).map do |name, value|
      name unless value
    end.compact
  end
end
