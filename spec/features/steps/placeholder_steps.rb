placeholder :model_instance do
  match(/([^ $]+) "([^$\n]+)"/) do |model_name, identifier|
    model_name = model_name.classify
    case model_name
    when 'Study' then Study.find_by(name: identifier)
    when 'Center' then Center.find_by(name: identifier)
    when 'Patient' then Patient.find_by(subject_id: identifier)
    when 'User' then User.find_by(username: identifier)
    end
  end
end

placeholder :study_instance do
  match(/"([^"]+)"/) do |identifier|
    Study.find_by(name: identifier)
  end
end
placeholder :center_instance do
  match(/"([^"]+)"/) do |identifier|
    Center.find_by(name: identifier)
  end
end
placeholder :patient_instance do
  match(/"([^"]+)"/) do |identifier|
    Patient.find_by(subject_id: identifier)
  end
end
placeholder :user_instance do
  match(/"([^"]+)"/) do |identifier|
    User.find_by(username: identifier)
  end
end
placeholder :role_instance do
  match(/"([^"]+)"/) do |identifier|
    Role.find_by(title: identifier)
  end
end
