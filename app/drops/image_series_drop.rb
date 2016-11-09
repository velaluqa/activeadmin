class ImageSeriesDrop < Liquid::Rails::Drop # :nodoc:
  attributes(
    :id,
    :visit_id,
    :patient_id,
    :state,
    :series_number,
    :name,
    :comment,
    :imaging_date,
    :properties,
    :properties_version,
    :domino_unid,
    :created_at,
    :updated_at
  )

  belongs_to(:visit)
  belongs_to(:patient)
  has_many(:images)
end
