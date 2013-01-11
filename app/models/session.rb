class Session < ActiveRecord::Base
  attr_accessible :name, :study, :study_id

  belongs_to :study

  has_many :roles, :as => :object
  has_many :form_answers
  has_many :patients
  has_many :session_pauses
  has_many :forms
  has_many :cases

  has_and_belongs_to_many :readers, :class_name => 'User', :join_table => 'readers_sessions'
  has_and_belongs_to_many :validators, :class_name => 'User', :join_table => 'validators_sessions'

  scope :blind_readable_by_user, lambda { |user| user.blind_readable_sessions.includes(:study) }

  def configuration
    begin
      config = YAML.load_file(Rails.application.config.session_configs_directory + "/#{id}.yml")
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

  private

  
end
