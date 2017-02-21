placeholder :activity do
  activities = Ability::ACTIVITIES.values.flatten.uniq
  match(/([^ $\n]+)/) do |activity|
    sym = activity.to_sym
    unless activities.include?(sym)
      fail "Activity `#{sym}` not defined in `Ability`"
    end
    sym
  end
end

placeholder :subject do
  match(/([^ $\n]+)/) do |subject|
    subject.classify.constantize
  end
end

placeholder :model do
  match(/([^ $\n]+)/) do |model_name|
    model_name.classify
  end
end

placeholder :admin_path do
  match(/([^ $\n]+) ([^ $]+) "([^$\n]+)"/) do |action, model_name, identifier|
    method = "admin_#{model_name.underscore}_path"
    method = "#{action}_#{method}" if action != 'show'
    model_name = model_name.classify
    record =
      case model_name
      when 'Study' then Study.find_by(name: identifier)
      when 'Center' then Center.find_by(name: identifier)
      when 'Patient' then Patient.find_by(subject_id: identifier)
      when 'User' then User.find_by(username: identifier)
      end
    Rails.application.routes.url_helpers.
      send(method, record)
  end

  match(/([^ $]+) "([^$\n]+)"/) do |model_name, identifier|
    model_name = model_name.classify
    record =
      case model_name
      when 'Study' then Study.find_by(name: identifier)
      when 'Center' then Center.find_by(name: identifier)
      when 'Patient' then Patient.find_by(subject_id: identifier)
      when 'User' then User.find_by(username: identifier)
      when 'Role' then Role.find_by(title: identifier)
      end
    Rails.application.routes.url_helpers.
      send("admin_#{model_name.singularize.underscore}_path", record)
  end

  match(/([^$\n]+) list/) do |model_name|
    Rails.application.routes.url_helpers.
      send("admin_#{model_name.underscore.pluralize}_path")
  end

  match(/([^ $\n]+) ([^ $]+)/) do |action, model_name|
    method = "admin_#{model_name.underscore}_path"
    method = "#{action}_#{method}" if action != 'index'
    Rails.application.routes.url_helpers.send(method)
  end
end

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
