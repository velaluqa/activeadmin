json.call(visit,
          :patient_id,
          :visit_number,
          :description,
          :visit_type,
          :state)
json.required_series(visit.required_series_names)
