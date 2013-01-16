require 'csv'

class Case < ActiveRecord::Base
  belongs_to :session
  belongs_to :patient
  has_one :form_answer
  has_one :case_data
  attr_accessible :images, :position, :case_type
  attr_accessible :session_id, :patient_id
  attr_accessible :session, :patient

  validates_uniqueness_of :position, :scope => :session_id

  before_destroy do |c|
    CaseData.destroy_all(:case_id => c.id)
  end

  # so we always get results sorted by position, not by row id
  default_scope order('position ASC')

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
    {'patient' => (self.patient.patient_data.nil? ? {} : self.patient.patient_data.data),
      'case' => (self.case_data.nil? ? {} : self.case_data.data)}
  end

  def images_folder
    "#{self.patient.subject_id}/#{read_attribute(:images)}"
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
      patient = Patient.create(:subject_id => subject_id, :session => session, :images_folder => subject_id) if patient.nil?

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
