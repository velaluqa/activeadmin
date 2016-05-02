class Permission < ActiveRecord::Base
  belongs_to :role
  has_many :users, through: :roles

  # Get the activity as symbol.
  #
  # @return [Symbol] The activity as symbol
  def activity
    read_attribute(:activity).to_sym
  end

  # Set the activity as string.
  #
  # @param [Symbol, String] activity A permissible activity (defaults
  #   are `:read`, `:update`, `:create`, `:destroy`)
  def activity=(activity)
    write_attribute(:activity, activity.to_s)
  end

  # Get the subject constant.
  #
  # @return [Class<ActiveRecord::Base>] The subject for this permission
  def subject
    read_attribute(:subject).constantize
  end

  # Set the subject as string.
  #
  # @param [Class<ActiveRecord::Base>, String] subject A cancan subject
  def subject=(subject)
    write_attribute(:subject, subject.to_s)
  end

  def to_s
    "Permission[#{activity} #{subject}]"
  end
end
