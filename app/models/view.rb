require 'csv'

class View < ActiveRecord::Base
  belongs_to :session
  belongs_to :patient
  attr_accessible :images, :position, :view_type
  attr_accessible :session_id, :patient_id
  attr_accessible :session, :patient

  validates_uniqueness_of :position, :scope => :session_id

  # so we always get results sorted by position, not by row id
  default_scope order('position ASC')

  def self.batch_create_from_csv(csv_file, session, start_position)
    csv_options = {
      :col_sep => ',',
      :row_sep => :auto,
      :quote_char => '"',
      :headers => false,
    }

    csv = CSV.new(csv_file, csv_options)
    rows = csv.read

    position = start_position
    rows.each do |row|
      patient = Patient.where(:subject_id => row[0], :session_id => session.id).first
      patient = Patient.create(:subject_id => row[0], :session => session, :images_folder => row[0]) if patient.nil?

      pp View.create(:patient => patient, :session => session, :images => row[1], :view_type => row[2], :position => position)
      position += 1
    end

    return rows.size
  end
end
