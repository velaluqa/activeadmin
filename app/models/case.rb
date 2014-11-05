require 'csv'

class Case < ActiveRecord::Base
  has_paper_trail

  belongs_to :session
  belongs_to :patient
  has_one :form_answer
  has_one :case_data
  belongs_to :assigned_reader, :class_name => 'User', :inverse_of => :assigned_cases
  belongs_to :current_reader, :class_name => 'User', :inverse_of => :current_cases

  attr_accessible :images, :position, :case_type, :state, :flag
  attr_accessible :session_id, :patient_id
  attr_accessible :session, :patient
  attr_accessible :exported_at, :no_export
  attr_accessible :comment
  attr_accessible :assigned_reader_id, :current_reader_id
  attr_accessible :is_adjudication_background_case

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

  STATE_SYMS = [:unread, :in_progress, :read, :reopened, :reopened_in_progress, :postponed]

  def self.state_sym_to_int(sym)
    return Case::STATE_SYMS.index(sym)
  end
  def self.int_to_state_sym(sym)
    return Case::STATE_SYMS[sym]
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
  def self.int_to_flag_sym(sym)
    return Case::FLAG_SYMS[sym]
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
    FormAnswer.where(:case_id => read_attribute(:id), :is_obsolete.ne => true).first
  end

  def obsolete_form_answers
    FormAnswer.where(:case_id => read_attribute(:id), :is_obsolete => true)
  end
  def latest_obsolete_form_answer
    FormAnswer.where(:case_id => read_attribute(:id), :is_obsolete => true).order_by(:submitted_at.desc).first
  end

  def case_data
    CaseData.where(:case_id => read_attribute(:id)).first
  end
  def data_hash
    result = {'patient' => ((self.patient.nil? or self.patient.patient_data.nil?) ? {} : self.patient.patient_data.data),
      'case' => (self.case_data.nil? ? {} : self.case_data.data)}

    result['patient']['id'] = (self.patient.nil? ? 'Unknown' : self.patient.subject_id)
    result['case']['id'] = self.id
    result['case']['images'] = self.images
    result['case']['images_folder'] = self.images_folder
    result['case']['position'] = self.position
    result['case']['case_type'] = self.case_type
    result['case']['flag'] = self.flag
    result['case']['state'] = self.state

    reader = ((self.form_answer.nil? or self.form_answer.user.nil?) ? nil : self.form_answer.user)
    if(reader.nil?)
      result['case']['reader_name'] = ''
      result['case']['reader_id'] = ''
    else
      result['case']['reader_name'] = reader.name
      result['case']['reader_id'] = reader.id
    end

    return result
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
      :flag => self.flag,
      :state => self.state,
      :is_adjudication_background_case => (self.is_adjudication_background_case == true),
    }      
  end

  def self.batch_create_from_csv(csv_file, case_flag, session, start_position)
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
      subject_id = row.unconverted_fields[row.index('patient')]
      images = row.unconverted_fields[row.index('images')]
      case_type = row.unconverted_fields[row.index('type')]
      patient = Patient.where(:subject_id => subject_id, :session_id => session.id).first
      patient = Patient.create(:subject_id => subject_id, :session => session) if patient.nil?

      is_adjudication_background_case = (row.index('background') and row['background'])

      new_case = Case.create(:patient => patient, :session => session, :images => images, :case_type => case_type, :position => position, :flag => case_flag, :is_adjudication_background_case => is_adjudication_background_case)
      
      case_data = {}
      data_headers = row.headers.reject {|h| ['patient', 'images', 'type', 'adjudication', 'background'].include?(h)}
      data_headers.each do |field|
        case_data[field] = row[field]
      end

      adjudication_data = {}
      unless(row.index('adjudication').nil? or row.unconverted_fields[row.index('adjudication')].blank?)
        adjudication_config = row.unconverted_fields[row.index('adjudication')].split(':').map {|s| s.to_i}
        adjudication_data['assignment'] = adjudication_config
      end

      CaseData.create(:case => new_case, :data => case_data, :adjudication_data => adjudication_data)
      
      position += 1
    end

    return rows.size
  end

  def self.classify_audit_trail_event(c)
    if(c.include?('state'))
      case [int_to_state_sym(c['state'][0]), c['state'][1]]
      when [:unread, :in_progress], [:reopened, :reopened_in_progress]
        :reservation
      when [:in_progress, :unread], [:reopened_in_progress, :reopened]
        :cancelation
      when [:in_progress, :read], [:reopened_in_progress, :read]
        :completion
      when [:read, :reopened]
        :reopened
      when [:reopened, :read]
        :reopen_closed
      when [:unread, :postponed]
        :postponed
      when [:postponed, :unread]
        :unpostponed
      when [:read, :unread]
        :obsoleted
      when [:unread, :read]
        :unobsoleted
      else :state_change
      end
    elsif(c.include?('flag'))
      case c['flag'][1]
      when :regular then :flag_regular
      when :validation then :flag_validation
      when :reader_testing then :flag_reader_testing
      end
    elsif(c.include?('no_export'))
      if(c['no_export'][1])
        :no_export_set
      else
        :no_export_unset
      end
    elsif(c.include?('is_adjudication_background_case'))
      if(c['is_adjudication_background_case'][1])
        :adjudication_background_set
      else
        :adjudication_background_unset
      end
    elsif(c.keys == ['assigned_reader_id'])
      if(c['assigned_reader_id'][1].blank?)
        :reader_unassigned
      elsif(c['assigned_reader_id'][0].blank?)
        :reader_assigned
      else
        :reader_changed
      end
    elsif(c.include?('current_reader_id') and c.include?('assigned_reader_id') and c.keys.length == 2)
      :automatic_reader_assignment
    elsif(c.keys == ['position'])
      :position_change
    elsif(c.keys == ['comment'])
      :comment_change
    elsif(c.keys == ['current_reader_id'])
      :current_reader_change
    elsif(c.keys == ['exported_at'])
      :export
    elsif(c.keys == ['images'])
      :images_change
    elsif(c.keys == ['case_type'])
      :case_type_change
    end
  end
  def self.audit_trail_event_title_and_severity(event_symbol)
    return case event_symbol
           when :reservation then ['Case Reservation', :warning]
           when :cancelation then ['Case Cancelation', :error]
           when :completion then ['Case Completion', :ok]
           when :reopened then ['Case reopened', :error]
           when :reopen_closed then ['Reopened case closed', :ok]
           when :obsoleted then ['Form Answer marked obsolete', :error]
           when :unobsoleted then ['Form Answer "unobsoleted"', :error]
           when :postponed then ['Case postponed', :warning]
           when :unpostponed then ['Case unpostponed', :warning]
           when :state_change then ['State Change', :warning]
           when :no_export_set then ['No Export flag set', :ok]
           when :no_export_unset then ['No Export flag unset', :ok]
           when :adjudication_background_set then ['Adjudication Background flag set', :ok]
           when :adjudication_background_unset then ['Adjudication Background flag unset', :ok]
           when :flag_regular then ['Marked as regular case', :warning]
           when :flag_validation then ['Marked as validation case', :warning]
           when :flag_reader_testing then ['Marked as reader testing case', :warning]
           when :reader_unassigned then ['Reader unassigned', :ok]
           when :reader_assigned then ['Reader assigned', :ok]
           when :reader_changed then ['Assigned reader changed', :ok]
           when :automatic_reader_assignment then ['Automatic reader assignment', :ok]
           when :position_change then ['Position Change', :ok]
           when :current_reader_change then ['Current Reader Change (Case Reservation)', :ok]
           when :export then ['Export', :ok]
           when :images_change then ['Images/Visit Change', :error]
           when :case_type_change then ['Case Type Change', :error]
           end
  end
end
