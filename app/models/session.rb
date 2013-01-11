class Session < ActiveRecord::Base
  attr_accessible :name, :study, :user, :study_id, :user_id

  belongs_to :study
  belongs_to :user

  has_many :roles, :as => :object
  has_many :form_answers
  has_many :patients
  has_many :session_pauses
  has_many :forms
  has_many :cases

  scope :blind_readable_by_user, lambda { |user| where(:user_id => user.id).includes(:study) }

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
