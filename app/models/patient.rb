class Patient < ActiveRecord::Base
  attr_accessible :images_folder, :session, :subject_id, :session_id

  belongs_to :session
  has_many :form_answers
end
