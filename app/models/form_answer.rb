require 'openssl'
require 'base64'
require 'key_path_accessor'

class FormAnswer
  include Mongoid::Document

  field :user_id, type: Integer
  field :session_id, type: Integer
  field :case_id, type: Integer
  field :form_id, type:  Integer
  field :form_version, type:  String
  field :submitted_at, type:  Time
  field :answers, type:  Hash
  field :answers_signature, type:  String
  field :annotated_images, type:  Hash
  field :annotated_images_signature, type:  String
  field :is_test_data, type: Boolean
  field :versions, type: Array

  before_destroy do
    c = self.case
    c.state = :unread
    c.save
  end

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

  def version_current_answers
    new_version = {}
    new_version[:answers] = self.answers
    new_version[:answers_signature] = self.answers_signature
    new_version[:annotated_images] = self.annotated_images
    new_version[:annotated_images_signature] = self.annotated_images_signature
    new_version[:submitted_at] = self.submitted_at

    self.versions = [] if self.versions.nil?
    self.versions << new_version
    self.save
  end

  def answers_signature_is_valid?
    return signature_is_valid?(read_attribute(:answers), read_attribute(:answers_signature))
  end
  def annotated_images_signature_is_valid?
    return signature_is_valid?(read_attribute(:annotated_images), read_attribute(:annotated_images_signature))
  end

  def signature_is_valid?(data, signature)
    key = user_public_key_rsa
    return false if (key.nil? or data.nil? or signature.nil?)
    canonical_data = FormAnswer::canonical_json(data)
    signature_raw = Base64.decode64(signature)
    
    return key.verify(OpenSSL::Digest::RIPEMD160.new, signature_raw, canonical_data)
  end

  def printable_answers
    form_config, form_components, repeatables = form.full_configuration_at_version(self.form_version)
    return nil if (form_config.nil? or repeatables.nil?)

    repeatables_map = {}
    repeatables.each do |r|
      repeatables_map[r[:id]] = r[:config]
    end

    return form_config_and_answers_to_display_list(form_config, repeatables_map, answers)
  end
  def printable_answers_for_version(i)
    return nil if i >= self.versions.size
    form_config, form_components, repeatables = form.full_configuration_at_version(self.form_version)
    return nil if (form_config.nil? or repeatables.nil?)

    repeatables_map = {}
    repeatables.each do |r|
      repeatables_map[r[:id]] = r[:config]
    end

    return form_config_and_answers_to_display_list(form_config, repeatables_map, self.versions[i]['answers'])
  end

  def form_fields_hash
    @form_fields_hash ||= generate_form_fields_hash

    return @form_fields_hash
  end
  def form_fields_hash!
    @form_fields_hash = generate_form_fields_hash

    return @form_fields_hash
  end

  def self.pretty_print_answer(field, answer)
   case field['type']
   when 'bool'
     return (answer == true ? 'Yes' : 'No')
   when 'select'
     return FormAnswer.pretty_print_select_answer(field, answer)
   when 'select_multiple'
     return 'None' if answer.nil?
     return answer.map {|a| FormAnswer.pretty_print_select_answer(field, a)}.join(', ')
   when 'roi'
     return FormAnswer.printable_roi_answer(field, answer)
   end

    return nil
  end
  
  private

  def generate_form_fields_hash
    form_config, form_components, repeatables = form.full_configuration_at_version(self.form_version)
    return [nil, nil] if (form_config.nil? or repeatables.nil?)

    repeatables_map = {}
    repeatables.each do |r|
      r_map = {}
      r[:config].each do |field|
        next if field['id'].nil?
        id = field['id'].slice(4..-2)

        r_map[id] = field
      end
      repeatables_map[r[:id]] = r_map
    end

    form_fields_map = {}
    form_config.each do |field|
      form_fields_map[field['id']] = field unless field['id'].nil?
    end

    return  [form_fields_map, repeatables_map]
  end

  def form_config_and_answers_to_display_list(form_config, repeatables, answers, indices = [])
    display_list = []

    skip_group = false
    while(field = form_config.shift)
      next if (skip_group and field['type'] != 'include_end')

      id = field['id']
      indices_copy = indices.clone
      id = id.gsub(/\[\]/) {|match| "[#{indices_copy.shift.to_s}]"} unless id.nil?

      case field['type']
      when 'include_start'
        display_list << field
        skip_group = true

        repeatable = repeatables[field['id']]
        repeatable_answer = KeyPathAccessor::access_by_path(answers, id)
        next if repeatable_answer.nil?

        repeatable_answer.each_with_index do |answer, i|
          display_list += form_config_and_answers_to_display_list(Marshal.load(Marshal.dump(repeatable)), repeatables, answers, indices + [i])
        end
      when 'include_end'
        display_list << field
        skip_group = false
      when 'include_divider', 'group', 'section'
        display_list << field
      else
        answer = KeyPathAccessor::access_by_path(answers, id)
        answer = FormAnswer.pretty_print_answer(field, answer)

        if field['type'] == 'roi'
          field.merge!({'seriesUID' => answer['location']['seriesUID'], 'imageIndex' => answer['location']['imageIndex'].to_i}) unless answer['location'].nil?
        end

        display_list << field.merge({'answer' => answer, 'id' => id})
      end
    end

    return display_list
  end

  def self.printable_roi_answer(field, roi_answer)
    return 'None given' if roi_answer.nil?
    return pretty_print_select_answer(field, roi_answer) unless roi_answer.respond_to?(:map)

    mapped_answer = roi_answer.map do |key, value|
      if key == 'location'
        "Location: #{value['seriesUID']} ##{value['imageIndex'].to_i}"
      else
        "#{key}: #{value}"
      end
    end
   
    mapped_answer.join("\n")
  end

  def self.pretty_print_select_answer(field, answer)
    if (answer.respond_to?(:'empty?') and answer.empty?)
      "None given"
    elsif (field['values'][answer].nil? and answer.is_a?(Float))
      "#{field['values'][answer.to_i.to_s]} (#{answer})"          
    else
      "#{field['values'][answer]} (#{answer})"
    end          
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
