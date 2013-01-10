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
    config = YAML.load_file(Rails.application.config.session_configs_directory + "/#{id}.yml")
    return config
  end

  def case_list(only_unread = true)
    if only_unread
      self.cases.where('position >= :next_case_position', {:next_case_position => self.next_case_position})
    else
      self.cases
    end
  end

  def most_recent_pause
    return self.session_pauses.order("end DESC").first
  end
  def current_case
    pause = most_recent_pause
    return nil if pause.nil?

    return pause.last_case
  end

  def next_case_position
    return 0 if current_case.nil?
    return current_case.position+1
  end

  private

  
end
