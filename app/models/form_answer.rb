class FormAnswer < ApplicationRecord
  include ConfigurationPathAccessor

  before_create :set_sequence_number_for_session

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

  has_many(:form_answer_resources)
  accepts_nested_attributes_for :form_answer_resources, allow_destroy: true
  has_many(:resources, through: :form_answer_resources)

  belongs_to(:user, optional: true)
  belongs_to(:study, optional: true)
  belongs_to(:form_session, optional: true)

  belongs_to(:blocking_user, class_name: "User", optional: true)

  scope :without_session, -> { where(form_session_id: nil) }
  scope :with_session, -> { where.not(form_session_id: nil) }
  scope :assigned_to, ->(user) { where(user_id: user.id) }

  scope :draft, -> { where("submitted_at IS NULL AND published_at IS NULL") }
  scope :published, -> { where("submitted_at IS NULL AND published_at IS NOT NULL") }
  scope :signed, -> { where("public_key_id IS NOT NULL AND answers IS NOT NULL") }

  scope :unassigned, -> { where("user_id IS NULL") }
  scope :assigned, -> { where("user_id IS NOT NULL") }

  scope :answerable_by, ->(user) { published.merge(unassigned.or(assigned_to(user))) }

  attr_configuration_path_accessor :validates_study_id, %w[config form_answers validates_study_id], default: "none"
  attr_configuration_path_accessor :validates_form_session_id, %w[config form_answers validates_form_session_id], default: "none"
  attr_configuration_path_accessor :validates_resource_id, %w[config form_answers validates_resource_id], default: "none"
  attr_configuration_path_accessor :validates_user_id, %w[config form_answers validates_user_id], default: "none"
  attr_configuration_path_accessor :validates_resource_type, %w[config form_answers validates_resource_type], default: "any"
  attr_configuration_path_accessor :allow_saving_draft, %w[config form_answers allow_saving_draft], default: false

  attr_configuration_path_accessor :layout, %w[layout], default: {}

  validates_associated :form_answer_resources
  validates :user, presence: true, if: -> { validates_user_id == "required" }
  validates :study, presence: true, if: -> { validates_study_id == "required" }
  validates :form_session, presence: true, if: -> { validates_form_session_id == "required" }
  validates :form_answer_resources, length: { minimum: 1, message: "must have at least one" }, if: -> { validates_resource_id == "required" }
  validates :form_answer_resources, length: { maximum: 0, message: "is not allowed by form definition" }, if: -> { validates_resource_id == "none" }
  validates :form_answer_resources, length: { minimum: 0 }, if: -> { validates_resource_id == "optional" }


  scope :searchable, -> { joins(:form_definition).select(<<~SELECT) }
    NULL::integer AS study_id,
    NULL::varchar AS study_name,
    form_definitions.name AS text,
    form_answers.id::varchar AS result_id,
    'FormAnswer'::varchar AS result_type
  SELECT

  def self.granted_for(options = {})
    activities = Array(options[:activity]) + Array(options[:activities])
    user = options[:user] || raise("Missing 'user' option")
    all
  end

  def answers_json
    JSON.dump(answers)
  end

  def answers_json=(answers)
    self.answers = JSON.parse(answers)
  end

  def resource_identifier
    return nil unless resource

    "#{resource_type}_#{resource_id}"
  end

  def resource_identifier=(identifier)
    return self.resource = nil unless identifier

    match = identifier.match(/^(?<type>.*)_(?<id>\d+)$/)
    return unless match

    self.resource_id = match[:id].to_i
    self.resource_type = match[:type].classify
  end

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

  def status
    if signed?
      "signed"
    elsif published?
      "published"
    elsif draft?
      "draft"
    end
  end

  def signature_status
    if !answers_signature
      "none"
    elsif valid_signature?
      "valid"
    else
      "invalid"
    end
  end

  def signed?
    answers_signature.present? || annotated_images_signature.present?
  end

  def published?
    !!published_at
  end

  def draft?
    !published? && !signed?
  end

  def form_definition_label
    form_definition.name
  end

  def user_label
    user.try(:name)
  end

  def resource_labels
    form_answer_resources.map(&:resource).map(&:to_s).join(", ")
  end

  def published_at_label
    published_at || "Not published"
  end

  def submitted_at_label
    submitted_at || "Not submitted"
  end

  def publish!
    self.published_at = DateTime.now
    save!
  end

  def unblock!
    self.blocked_at = nil
    self.blocking_user = nil
    save!
  end

  def unblock_expired!
    unblock! if block_expired?
  end

  def block_expired?
    blocked? && blocked_at < 30.minutes.ago
  end

  def blocked?
    blocked_at && blocking_user
  end

  def try_block_for!(user)
    return if blocking_user && blocking_user != user

    self.blocked_at = DateTime.now
    self.blocking_user = user
    save!
  end

  private

  def set_sequence_number_for_session
    return unless form_session
    return if sequence_number

    last_sequence_number = form_session.form_answers.order(sequence_number: :desc).first.andand.sequence_number || 0
    self.sequence_number = last_sequence_number + 1
  end
end
