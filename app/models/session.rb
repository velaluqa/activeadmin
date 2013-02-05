class Session < ActiveRecord::Base
  attr_accessible :name, :study, :study_id, :state, :locked_version

  belongs_to :study

  has_many :roles, :as => :subject
  has_many :form_answers
  has_many :patients
  has_many :session_pauses
  has_many :forms
  has_many :cases

  has_and_belongs_to_many :readers, :class_name => 'User', :join_table => 'readers_sessions'
  has_and_belongs_to_many :validators, :class_name => 'User', :join_table => 'validators_sessions'

  scope :blind_readable_by_user, lambda { |user| user.blind_readable_sessions.includes(:study) }

  STATE_SYMS = [:building, :testing, :production, :closed]

  def self.state_sym_to_int(sym)
    return Session::STATE_SYMS.index(sym)
  end
  def state
    return -1 if read_attribute(:state).nil?
    return Session::STATE_SYMS[read_attribute(:state)]
  end
  def state=(sym)
    sym = sym.to_sym if sym.is_a? String
    index = Session::STATE_SYMS.index(sym)

    if index.nil?
      throw "Unsupported state"
      return
    end

    write_attribute(:state, index)
  end
  
  def config_file_path
    Rails.application.config.session_configs_directory + "/#{id}.yml"
  end
  def relative_config_file_path
    Rails.application.config.session_configs_subdirectory + "/#{id}.yml"
  end

  def configuration
    begin
      config = YAML.load_file(config_file_path)
    rescue Errno::ENOENT => e
      return nil
    end
      
    return config
  end

  def case_list(mode = :unread)
    case mode
    when :unread
      self.cases.find_all {|c| c.form_answer.nil?}
    when :read
      self.cases.reject {|c| c.form_answer.nil?}        
    when :all
      self.cases
    end
  end

  def most_recent_pause
    return self.session_pauses.order("end DESC").first
  end

  def next_unread_case
    case_list(:unread).first
  end
  def last_read_case
    case_list(:read).last    
  end

  def next_position
    return 0 if self.cases.empty?
    return self.cases.last.position+1
  end

  private

  
end
