class StringArraySerializer
  def self.dump(array)
    Array(array).to_json
  end

  def self.load(array)
    array
  end
end
