class AddVisitsRepeatableCountToImagesSearchViews < ActiveRecord::Migration
  def up
    execute <<-SQL
      drop view if exists images_search;
    SQL

    execute <<-SQL
      drop view if exists visits_search;
    SQL
    execute <<-SQL
      drop view if exists patients_search;
    SQL
    execute <<-SQL
      drop view if exists centers_search;
    SQL
    execute <<-SQL
      drop view if exists studies_search;
    SQL

    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      execute <<-SQL
        create view studies_search as select studies.id as study_id, studies.name as text, 'study_' || studies.id as result_id, text 'study' as result_type from studies;
      SQL
      execute <<-SQL
        create view centers_search as select centers.study_id as study_id, centers.code || ' - ' || centers.name as text, 'center_' || centers.id as result_id, text 'center' as result_type from centers;
      SQL
      execute <<-SQL
        create view patients_search as select centers.study_id as study_id, centers.code || patients.subject_id as text, 'patient_' || patients.id as result_id, text 'patient' as result_type from patients, centers where centers.id = patients.center_id;
      SQL
      execute <<-SQL
        create view visits_search as
        select
          centers.study_id as study_id,
          centers.code ||
            patients.subject_id ||
            '#' ||
            visits.visit_number ||
            CASE WHEN visits.repeatable_count > 0 THEN ('.' || visits.repeatable_count) ELSE '' END
          as text,
          'visit_' || visits.id as result_id,
          text 'visit' as result_type
        from visits, patients, centers
        where
          visits.patient_id = patients.id and
          patients.center_id = centers.id
        ;
      SQL
      execute <<-SQL
        create view images_search as select * from studies_search union all select * from centers_search union all select * from patients_search union all select * from visits_search;
      SQL
    end
  end

  def down
    execute <<-SQL
      drop view if exists images_search;
    SQL

    execute <<-SQL
      drop view if exists visits_search;
    SQL
    execute <<-SQL
      drop view if exists patients_search;
    SQL
    execute <<-SQL
      drop view if exists centers_search;
    SQL
    execute <<-SQL
      drop view if exists studies_search;
    SQL

    execute <<-SQL
        create view studies_search as select studies.id as study_id, studies.name as text, 'study_' || studies.id as result_id, text 'study' as result_type from studies;
      SQL
    execute <<-SQL
        create view centers_search as select centers.study_id as study_id, centers.code || ' - ' || centers.name as text, 'center_' || centers.id as result_id, text 'center' as result_type from centers;
      SQL
    execute <<-SQL
        create view patients_search as select centers.study_id as study_id, centers.code || patients.subject_id as text, 'patient_' || patients.id as result_id, text 'patient' as result_type from patients, centers where centers.id = patients.center_id;
      SQL
    execute <<-SQL
        create view visits_search as select centers.study_id as study_id, centers.code || patients.subject_id || '#' || visits.visit_number as text, 'visit_' || visits.id as result_id, text 'visit' as result_type from visits,patients,centers where visits.patient_id = patients.id and patients.center_id = centers.id;
      SQL

    execute <<-SQL
        create view images_search as select * from studies_search union all select * from centers_search union all select * from patients_search union all select * from visits_search;
      SQL
  end
end
