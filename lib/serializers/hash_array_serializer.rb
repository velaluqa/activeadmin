class HashArraySerializer
  def self.dump(array)
    array.to_json
  end

  def self.load(array)
    array
  end
end
