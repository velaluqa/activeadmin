placeholder :activity do
  match(/([^ $\n]+)/) do |activity|
    activities = Ability::ACTIVITIES.values.flatten.uniq
    sym = activity.to_sym
    unless activities.include?(sym)
      raise "Activity `#{sym}` not defined in `Ability`"
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
  match(/([^ $\n]+)/, &:classify)
end

placeholder :admin_path do
  match(/the dashboard/) do
    '/admin/dashboard'
  end

  match(/([^ $\n]+) page/) do |page_name|
    Rails.application.routes.url_helpers
      .send("admin_#{page_name.underscore}_path")
  end

  match(/the latest ([^ $]+)/) do |model_name|
    model_name = model_name.classify
    record = model_name.constantize.last
    Rails.application.routes.url_helpers
      .send("admin_#{model_name.singularize.underscore}_path", record)
  end

  match(/([^ $\n]+) ([^ $]+) "([^$\n]+)"/) do |action, model_name, identifier|
    method = "admin_#{model_name.underscore}_path"
    method = "#{action}_#{method}" if action != 'show'
    model_name = model_name.classify
    record =
      case model_name
      when 'BackgroundJob' then BackgroundJob.find_by(id: identifier)
      when 'Study' then Study.find_by(name: identifier)
      when 'Center' then Center.find_by(name: identifier)
      when 'Patient' then Patient.find_by(subject_id: identifier)
      when 'Visit' then Visit.find_by(visit_number: identifier)
      when 'ImageSeries' then ImageSeries.find_by(name: identifier)
      when 'Image' then Image.find_by(id: identifier)
      when 'User' then User.find_by(username: identifier)
      when 'Role' then Role.find_by(title: identifier)
      end
    Rails.application.routes.url_helpers
         .send(method, record)
  end

  match(/([^ $]+) "([^$\n]+)"/) do |model_name, identifier|
    model_name = model_name.classify
    record =
      case model_name
      when 'BackgroundJob' then BackgroundJob.find_by(id: identifier)
      when 'Study' then Study.find_by(name: identifier)
      when 'Center' then Center.find_by(name: identifier)
      when 'Patient' then Patient.find_by(subject_id: identifier)
      when 'Visit' then Visit.find_by(visit_number: identifier)
      when 'ImageSeries' then ImageSeries.find_by(name: identifier)
      when 'Image' then Image.find_by(id: identifier)
      when 'User' then User.find_by(username: identifier)
      when 'Role' then Role.find_by(title: identifier)
      end
    Rails.application.routes.url_helpers
         .send("admin_#{model_name.singularize.underscore}_path", record)
  end

  match(/([^$\n]+) list/) do |model_name|
    if model_name.underscore.pluralize == model_name.underscore.singularize
      Rails.application.routes.url_helpers
        .send("admin_#{model_name.underscore.pluralize}_index_path")
    else
      Rails.application.routes.url_helpers
        .send("admin_#{model_name.underscore.pluralize}_path")
    end
  end

  match(/([^ $\n]+) ([^ $]+)( form)?/) do |action, model_name|
    method = "admin_#{model_name.underscore}_path"
    method = "#{action}_#{method}" if action != 'index'
    Rails.application.routes.url_helpers.send(method)
  end
end

placeholder :model_instance do
  match(/([^ $]+) "([^$\n]+)"/) do |model_name, identifier|
    model_name = model_name.classify
    case model_name
    when 'BackgroundJob' then BackgroundJob.find_by(id: identifier)
    when 'Study' then Study.find_by(name: identifier)
    when 'Center' then Center.find_by(name: identifier)
    when 'Patient' then Patient.find_by(subject_id: identifier)
    when 'User' then User.find_by(username: identifier)
    when 'Visit' then Visit.find_by(visit_number: identifier)
    when 'ImageSeries' then ImageSeries.find_by(name: identifier)
    end
  end
end

placeholder :background_job_instance do
  match(/"([^"]+)"/) do |identifier|
    BackgroundJob.find_by(id: identifier)
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
placeholder :visit_instance do
  match(/"([^"]+)"/) do |identifier|
    Visit.find_by(visit_number: identifier)
  end
end
placeholder :image_series_instance do
  match(/"([^"]+)"/) do |identifier|
    ImageSeries.find_by(name: identifier)
  end
end
