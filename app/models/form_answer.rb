class FormAnswer < ApplicationRecord
  has_paper_trail(
    class_name: 'Version',
    meta: {
      form_definition_id: ->(form_answer) { form_answer.form_definition.id },
      form_answer_id: ->(form_answer) { form_answer.id },
      configuration_id: ->(form_answer) { form_answer.configuration.id }
    }
  )

  belongs_to :form_definition
  belongs_to(
    :configuration,
    class_name: "Configuration",
    foreign_key: :configuration_id
  )
  belongs_to :public_key, optional: true
  has_many(
    :configurations,
    as: :configurable
  )

  def valid_signature?
    return false unless public_key && answers && answers_signature

    public_key_rsa = OpenSSL::PKey::RSA.new(public_key.public_key)
    canonical_data = answers.to_canonical_json
    raw_signature = Base64.decode64(answers_signature)

    result = public_key_rsa.verify(
      OpenSSL::Digest::RIPEMD160.new,
      raw_signature,
      canonical_data
    )
    OpenSSL.errors

    result
  end

  def pdfa
    return File.read(pdfa_path) if File.exist?(pdfa_path)

    result = FormAnswer::GeneratePdfa.call(
      params: {
        form_answer_id: id
      }
    )
    result[:pdfa]
  end

  def pdfa_path
    ERICA.form_pdf_path.join("#{id}.pdf").to_s
  end
end
