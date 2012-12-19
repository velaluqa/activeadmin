class FormAnswer
  include MongoMapper::Document

  key :reader, Integer
  key :read, Integer
  key :form_id, Integer
  key :submitted_at, Time
  key :answers, Hash
  key :signature, String

  
  private
  def canonical_answers
    FormAnswer::canonical_json(read_attribute[:answers])
  end

  def self.canonical_json(value)
    return case value
           when NilClass   then "null"
           when TrueClass  then "true"
           when FalseClass then "false"
           when Float      then canonical_json_float(value)
           when Fixnum     then canonical_json_fixnum(value)
           when String     then canonical_json_string(value)
           when Array      then canonical_json_array(value)
           when Hash       then canonical_json_hash(value)
           else                 nil
           end
  end

  def self.canonical_json_array(array)
    result = '['
    
    array.each do |element|
      result += canonical_json(element)
      result += ','
    end

    result.chop!
    result += ']'

    return result
  end
  def self.canonical_json_hash(hash)
    result = '{'
    
    hash.keys.sort.each do |key|
      result += canonical_json_string(key)
      result += ':'
      result += canonical_json(hash[key])
      result += ','
    end
    
    result.chop!
    result += '}'

    return result
  end

  def self.canonical_json_float(value)
    mantissa, exponent = Math.frexp(value)

    if(mantissa == 0)
      return "0.0E0"
    end

    return "%.13gE%i" % [mantissa, exponent]
  end
  def self.canonical_json_fixnum(value)
    return value.to_s
  end
  def self.canonical_json_string(value)
    return "\"#{value}\""
  end
end
