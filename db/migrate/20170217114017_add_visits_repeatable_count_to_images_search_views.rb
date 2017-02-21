class AddVisitsRepeatableCountToImagesSearchViews < ActiveRecord::Migration
  def up
    execute <<-SQL
      drop view if exists images_search;
    SQL
    execute <<-SQL
      drop view if exists visits_search;
    SQL
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
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
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      execute <<-SQL
        create view visits_search as select centers.study_id as study_id, centers.code || patients.subject_id || '#' || visits.visit_number as text, 'visit_' || visits.id as result_id, text 'visit' as result_type from visits,patients,centers where visits.patient_id = patients.id and patients.center_id = centers.id;
      SQL
      execute <<-SQL
        create view images_search as select * from studies_search union all select * from centers_search union all select * from patients_search union all select * from visits_search;
      SQL
    end
  end
end
