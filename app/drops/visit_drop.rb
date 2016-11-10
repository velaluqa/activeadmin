class VisitDrop < EricaDrop # :nodoc:
  attributes(
    :id,
    :state,
    :visit_type,
    :visit_number,
    :description,
    :required_series,
    :assigned_image_series_index,
    :mqc_comment,
    :mqc_date,
    :mqc_results,
    :mqc_state,
    :mqc_user_id,
    :mqc_version,
    :created_at,
    :updated_at,
    :domino_unid
  )

  belongs_to(:patient)
  has_many(:image_series)
  belongs_to(:mqc_user, class_name: 'UserDrop')
end
