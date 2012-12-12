class Form < ActiveRecord::Base
  has_paper_trail

  attr_accessible :description, :name

  validates :name, :presence => true
  validates :name, :uniqueness => true
  validates :name, :format => { :with => /^[a-zA-Z0-9_]+$/, :message => 'Only letters A-Z, numbers and \'_\' allowed' }
end
