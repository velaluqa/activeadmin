class CanonicalJSON
  class << self
    def from_array(array)
      result = '['

      result += array.map(&method(:from)).join(",")

      result += ']'
      result
    end

    def from_hash(hash)
      result = '{'

      result += hash.keys.sort_by(&:to_s).map { |key|
        "#{from_string(key)}:#{from(hash[key])}"
      }.join(",")

      result += '}'
      result
    end

    def from_numeric(value)
      return from_fixnum(value) if value.to_i == value

      from_float(value)
    end

    def from_boolean(value)
      case value
      when NilClass   then "null"
      when TrueClass  then "true"
      when FalseClass then "false"
      end
    end

    def from_string(value)
      "\"#{value}\""
    end

    def from_fixnum(value)
      value.to_i.to_s
    end

    def from_float(value)
      mantissa, exponent = Math.frexp(value)

      return "0.0E0" if mantissa == 0

      "%.13gE%i" % [mantissa, exponent]
    end

    def from(value)
      case value
      when NilClass   then "null"
      when TrueClass  then "true"
      when FalseClass then "false"
      when Numeric    then from_numeric(value)
      when String     then from_string(value)
      when Array      then from_array(value)
      when Hash       then from_hash(value)
      end
    end
  end
end

class Object
  def to_canonical_json
    CanonicalJSON.from(self)
  end
end
