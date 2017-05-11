class AddImagesSearchViews < ActiveRecord::Migration
  def up
    puts ActiveRecord::Base.connection.adapter_name
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      execute <<-SQL
        create view studies_search as select studies.name as text, 'study_' || studies.id as result_id, text 'study' as result_type from studies;
      SQL
      execute <<-SQL
        create view centers_search as select centers.code || ' - ' || centers.name as text, 'center_' || centers.id as result_id, text 'center' as result_type from centers;
      SQL
      execute <<-SQL
        create view patients_search as select centers.code || patients.subject_id as text, 'patient_' || patients.id as result_id, text 'patient' as result_type from patients, centers where centers.id = patients.center_id;
      SQL
      execute <<-SQL
        create view visits_search as select centers.code || patients.subject_id || '#' || visits.visit_number as text, 'visit_' || visits.id as result_id, text 'visit' as result_type from visits,patients,centers where visits.patient_id = patients.id and patients.center_id = centers.id;
      SQL

      execute <<-SQL
        create view images_search as select * from studies_search union all select * from centers_search union all select * from patients_search union all select * from visits_search;
      SQL
    else
      execute <<-SQL
        create view studies_search as select studies.name as text, 'study_' || studies.id as result_id, 'study' as result_type from studies;
      SQL
      execute <<-SQL
        create view centers_search as select centers.code || ' - ' || centers.name as text, 'center_' || centers.id as result_id, 'center' as result_type from centers;
      SQL
      execute <<-SQL
        create view patients_search as select centers.code || patients.subject_id as text, 'patient_' || patients.id as result_id, 'patient' as result_type from patients, centers where centers.id = patients.center_id;
      SQL
      execute <<-SQL
        create view visits_search as select centers.code || patients.subject_id || '#' || visits.visit_number as text, 'visit_' || visits.id as result_id, 'visit' as result_type from visits,patients,centers where visits.patient_id = patients.id and patients.center_id = centers.id;
      SQL

      execute <<-SQL
        create view images_search as select * from studies_search union all select * from centers_search union all select * from patients_search union all select * from visits_search;
      SQL
    end
  end

  def down
    execute <<-SQL
      drop view images_search;
    SQL

    execute <<-SQL
      drop view visits_search;
    SQL
    execute <<-SQL
      drop view patients_search;
    SQL
    execute <<-SQL
      drop view centers_search;
    SQL
    execute <<-SQL
      drop view studies_search;
    SQL
  end
end
