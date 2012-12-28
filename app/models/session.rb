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

  def view_sequence
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

    return sequence
  end

  private

  
end
