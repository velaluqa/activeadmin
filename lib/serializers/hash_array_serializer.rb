class HashArraySerializer
  def self.dump(array)
    array.to_json
  end

  def self.load(array)
    (array || []).map(&:with_indifferent_access)
  end
end
