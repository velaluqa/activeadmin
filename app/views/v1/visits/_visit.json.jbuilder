json.call(visit,
          :id,
          :patient_id,
          :visit_number,
          :description,
          :visit_type)
json.state visit.state_sym
json.required_series(visit.required_series_names)
