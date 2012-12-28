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

  scope :blind_readable_by_user, lambda { |user| where(:user_id => user.id).includes(:study) }

  def configuration
    config = YAML.load_file(Rails.application.config.session_configs_directory + "/#{id}.yml")
    return config
  end

  def view_sequence(only_unread = true)
    csv_options = {
      :col_sep => ',',
      :row_sep => :auto,
      :quote_char => '"',
      :headers => false,
    }

    sequence = File.open(Rails.application.config.session_configs_directory + "/#{id}.csv", 'r') do |f|
      csv = CSV.new(f, csv_options)
      csv.read
    end

    sequence_as_hashes = sequence.map do |row|
      {:subject => row[0], :images => row[1], :type => row[2]}
    end

    if only_unread
      return sequence_as_hashes[current_sequence_row..-1]
    else
      return sequence_as_hashes
    end
  end

  def most_recent_pause
    return self.session_pauses.order("end DESC").first
  end
  def current_sequence_row
    pause = most_recent_pause
    return 0 if pause.nil?

    return pause.sequence_row
  end

  private

  
end
