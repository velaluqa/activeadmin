require 'csv'

class Session < ActiveRecord::Base
  attr_accessible :name, :study, :user, :study_id, :user_id

  belongs_to :study
  belongs_to :user

  has_many :roles, :as => :object
  has_many :form_answers
  has_many :patients
  has_many :session_pauses
  has_many :forms
  has_many :views

  scope :blind_readable_by_user, lambda { |user| where(:user_id => user.id).includes(:study) }

  def configuration
    config = YAML.load_file(Rails.application.config.session_configs_directory + "/#{id}.yml")
    return config
  end

  def view_sequence(only_unread = true)
    if only_unread
      self.views.where('position >= :next_view_position', {:next_view_position => self.next_view_position})
    else
      self.views
    end
  end

  def most_recent_pause
    return self.session_pauses.order("end DESC").first
  end
  def current_view
    pause = most_recent_pause
    return nil if pause.nil?

    return pause.last_view
  end

  def next_view_position
    return 0 if current_view.nil?
    return current_view.position+1
  end

  private

  
end
