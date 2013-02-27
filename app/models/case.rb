require 'csv'

class Case < ActiveRecord::Base
  belongs_to :session
  belongs_to :patient
  has_one :form_answer
  has_one :case_data
  attr_accessible :images, :position, :case_type, :state, :flag
  attr_accessible :session_id, :patient_id
  attr_accessible :session, :patient

  validates_uniqueness_of :position, :scope => :session_id  

  before_destroy do
    unless form_answer.nil?
      errors.add :base, 'You cannot delete a case that was answered' 
      return false
    end

    CaseData.destroy_all(:case_id => self.id)
  end

  # so we always get results sorted by position, not by row id
  default_scope order('position ASC')

  STATE_SYMS = [:unread, :in_progress, :read]

  def self.state_sym_to_int(sym)
    return Case::STATE_SYMS.index(sym)
  end
  def state
    return -1 if read_attribute(:state).nil?
    return Case::STATE_SYMS[read_attribute(:state)]
  end
  def state=(sym)
    sym = sym.to_sym if sym.is_a? String
    index = Case::STATE_SYMS.index(sym)

    if index.nil?
      throw "Unsupported state"
      return
    end

    write_attribute(:state, index)
  end

  FLAG_SYMS = [:regular, :validation, :reader_testing]

  def self.flag_sym_to_int(sym)
    return Case::FLAG_SYMS.index(sym)
  end
  def flag
    return -1 if read_attribute(:flag).nil?
    return Case::FLAG_SYMS[read_attribute(:flag)]
  end
  def flag=(sym)
    sym = sym.to_sym if sym.is_a? String
    index = Case::FLAG_SYMS.index(sym)

    if index.nil?
      throw "Unsupported flag"
      return
    end

    write_attribute(:flag, index)
  end

  # virtual attribute for pretty names
  def name
    images_folder
  end

  def form_answer
    FormAnswer.where(:case_id => read_attribute(:id)).first
  end

  def case_data
    CaseData.where(:case_id => read_attribute(:id)).first
  end
  def data_hash
    {'patient' => ((self.patient.nil? or self.patient.patient_data.nil?) ? {} : self.patient.patient_data.data),
      'case' => (self.case_data.nil? ? {} : self.case_data.data)}
  end

  def images_folder
    if patient.nil?
      read_attribute(:images)
    else
      "#{self.patient.subject_id}/#{read_attribute(:images)}"
    end
  end

  def to_hash
    {
      :images => self.images,
      :images_folder => self.images_folder,
      :position => self.position,
      :id => self.id,
      :case_type => self.case_type,
      :patient => self.patient.nil? ? '' : self.patient.subject_id,
    }      
  end

  def self.batch_create_from_csv(csv_file, session, start_position)
    csv_options = {
      :col_sep => ',',
      :row_sep => :auto,
      :quote_char => '"',
      :headers => true,
      :converters => [:all, :date],
      :unconverted_fields => true,
    }

    csv = CSV.new(csv_file, csv_options)
    csv.convert do |field|
      if (field.downcase == 'true' or field.downcase == 'yes')
        true
      elsif (field.downcase == 'false' or field.downcase == 'no')
        false
      else
        field
      end
    end
    rows = csv.read

    position = start_position
    rows.each do |row|
      puts "------------------------"
      pp row
      pp row['visit_date']
      puts "------------------------"
      subject_id = row.unconverted_fields[row.index('patient')]
      images = row.unconverted_fields[row.index('images')]
      case_type = row.unconverted_fields[row.index('type')]
      patient = Patient.where(:subject_id => subject_id, :session_id => session.id).first
      patient = Patient.create(:subject_id => subject_id, :session => session) if patient.nil?

      new_case = Case.create(:patient => patient, :session => session, :images => images, :case_type => case_type, :position => position)
      
      case_data = {}
      data_headers = row.headers.reject {|h| ['patient', 'images', 'type'].include?(h)}
      data_headers.each do |field|
        case_data[field] = row[field]
      end

      CaseData.create(:case => new_case, :data => case_data)
      
      position += 1
    end

    return rows.size
  end
end
