require 'openssl'
require 'base64'

class FormAnswer
  include Mongoid::Document

  field :user_id, type: Integer
  field :session_id, type: Integer
  field :form_id, type:  Integer
  field :patient_id, type:  Integer
  field :submitted_at, type:  Time
  field :answers, type:  Hash
  field :signature, type:  String
  field :images, type:  String

  def session
    begin
      return Session.find(read_attribute(:session_id))
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end
  def user
    begin
      User.find(read_attribute(:user_id))
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end
  def form
    begin
      Form.find(read_attribute(:form_id))
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end
  def patient
    begin
      Patient.find(read_attribute(:patient_id))
    rescue ActiveRecord::RecordNotFound
      return nil
    end
  end

  def session=(session)
    write_attribute(:session_id, session.id)
  end
  def user=(user)
    write_attribute(:user_id, user.id)
  end
  def form=(form)
    write_attribute(:form_id, form.id)
  end
  def patient=(patient)
    write_attribute(:patient_id, patient.id)
  end

  def signature_is_valid?()
    key = user_public_key_rsa
    return false if key.nil?
    data = canonical_answers
    signature = Base64.decode64(read_attribute(:signature))
    
    return key.verify(OpenSSL::Digest::RIPEMD160.new, signature, data)
  end

  def printable_answers
    form_config, form_components, repeatables = form.configuration
    return nil if (form_config.nil? or repeatables.nil?)
    field_map = form_config_to_field_map(form_config, repeatables)

    return join_answers_with_config([], answers, field_map)
  end
  
  private
  def form_config_to_field_map(form_config, repeatables)
    field_map = {}

    form_config.each do |field|
      next if Form.config_field_has_special_type?(field)
      next if (field['id'] && field['id'].include?('[') and field['id'].include?(']'))

      field_map[field['id']] = {:label => field['label'], :type => field['type']}
    end

    repeatables.each do |repeatable|
      repeatable[:config].each do |field|
        next if Form.config_field_has_special_type?(field)
        
        field_map[field['id']] = {:label => field['label'], :type => field['type']}
      end
    end

    return field_map
  end

  def stringify_answer_key(key, keep_array_indices = false)
    result = key.first.to_s

    key.each_with_index do |elem, i|
      next if i == 0
      
      if (elem.class == Fixnum && !keep_array_indices)
        result += '[]'
      else
        result += "[#{elem.to_s}]"
      end
    end

    return result
  end
  def join_answer_with_config(key, value, field_map)
    key_string = stringify_answer_key(key)

    field_config = field_map[key_string]
    if field_config.nil?
      return {:label => stringify_answer_key(key, true), :answer => value, :type => 'unknown'}
    else
      return field_config.merge({:answer => value})
    end
  end
  def join_answers_with_config(prefix, answers, field_map)
    results = []

    case answers
    when Hash
      answers.each do |key, value|
        results += join_answers_with_config(prefix + [key], value, field_map)
      end
    when Array
      answers.each_with_index do |value, i|
        results += join_answers_with_config(prefix + [i], value, field_map)
      end
    else
      results << join_answer_with_config(prefix, answers, field_map)
    end

    return results
  end

  def user_public_key_rsa
    begin
      user = User.find(read_attribute(:user_id))
      return nil if user.nil?
    rescue ActiveRecord::RecordNotFound
      return nil
    end

    return OpenSSL::PKey::RSA.new(user.public_key)
  end

  def canonical_answers
    FormAnswer::canonical_json(read_attribute(:answers))
  end

  def self.canonical_json(value)
    return case value
           when NilClass   then "null"
           when TrueClass  then "true"
           when FalseClass then "false"
           when Numeric    then canonical_json_numeric(value)
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

  def self.canonical_json_numeric(value)
    if(value.to_i == value)
      return canonical_json_fixnum(value.to_i)
    else
      return canonical_json_float(value)
    end
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
