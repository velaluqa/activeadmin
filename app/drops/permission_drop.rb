class PermissionDrop < Liquid::Rails::Drop # :nodoc:
  attributes(
    :id,
    :activity,
    :subject,
    :created_at,
    :updated_at
  )

  belongs_to(:role)
  has_many(:users)

  delegate(:ability, to: :object)
end
