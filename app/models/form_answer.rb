require 'openssl'
require 'base64'
require 'key_path_accessor'

class FormAnswer
  include Mongoid::Document

  field :user_id, type: Integer
  field :session_id, type: Integer
  field :case_id, type: Integer
  field :form_id, type:  Integer
  field :submitted_at, type:  Time
  field :answers, type:  Hash
  field :signature, type:  String

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
  def case
    begin
      Case.find(read_attribute(:case_id))
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
  def case=(new_case)
    write_attribute(:case_id, new_case.id)
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

    repeatables_map = {}
    repeatables.each do |r|
      repeatables_map[r[:id]] = r[:config]
    end

    return form_config_and_answers_to_display_list(form_config, repeatables_map, answers)
  end
  
  private

  def pretty_print_select_answer(field, answer)
    if (answer.respond_to?(:'empty?') and answer.empty?)
      "None given"
    elsif (field['values'][answer].nil? and answer.is_a?(Float))
      "#{field['values'][answer.to_i]} (#{answer})"          
    else
      "#{field['values'][answer]} (#{answer})"
    end          
  end

  def form_config_and_answers_to_display_list(form_config, repeatables, answers, indices = [])
    display_list = []

    skip_group = false
    while(field = form_config.shift)
      next if (skip_group and field['type'] != 'group-end')

      id = field['id']
      indices_copy = indices.clone
      id = id.gsub(/\[\]/) {|match| "[#{indices_copy.shift.to_s}]"} unless id.nil?

      case field['type']
      when 'add_repeat'
        display_list << field
        skip_group = true

        repeatable = repeatables[field['id']]
        repeatable_answer = KeyPathAccessor::access_by_path(answers, id)
        next if repeatable_answer.nil?

        repeatable_answer.each_with_index do |answer, i|
          display_list += form_config_and_answers_to_display_list(Marshal.load(Marshal.dump(repeatable)), repeatables, answers, indices + [i])
        end
      when 'group-end'
        display_list << field
        skip_group = false
      when 'divider'
        display_list << field
      else
        answer = KeyPathAccessor::access_by_path(answers, id)
        case field['type']
        when 'bool'
          answer = (answer == true ? "Yes" : "No")
        when 'select'
          answer = pretty_print_select_answer(field, answer)
        when 'select_multiple'
          if answer.nil?
            answer = "None"
          else
            answer = answer.map {|a| pretty_print_select_answer(field, a)}.join(', ')
          end
        when 'roi'
          if answer.nil?
            answer = "None given"
          else
            answer = (answer.respond_to?(:map) ? answer.map {|k,v| "#{k}: #{v}"}.join(", ") : answer)
          end
        end
        display_list << field.merge({'answer' => answer, 'id' => id})
      end
    end

    return display_list
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
