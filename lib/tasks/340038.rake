namespace :erica do
  desc "Migrate old 340038 visit types/required series from GoodImage to new schema for ERICAv2"
  task :migrate_340038_visit_types => [:environment] do
    study = Study.find(2)
    next if study.nil?
   
    visits_count = study.visits.count

    puts "Attempting to migrate #{visits_count} visits to the new schema"
 
    study.visits.each_with_index do |visit, index|
      visit.required_series.keys.each do |old_rs_name|
        new_rs_name = nil
        
        if(old_rs_name.start_with?('abdomen_liver_scan_'))
          new_rs_name = 'abdomen_liver'
        elsif(old_rs_name.start_with?('lung_scan_'))
          new_rs_name = 'lung'
        elsif(old_rs_name.start_with?('additional_scan_'))
          new_rs_name = 'additional_1'
        elsif(old_rs_name.start_with?('add_scan_2_'))
          new_rs_name = 'additional_2'
         elsif(old_rs_name.start_with?('liver_scan_'))
          new_rs_name = 'additional_3'
        elsif(old_rs_name.start_with?('abdomen_scan_'))
          new_rs_name = 'additional_4'
        end

        unless(new_rs_name.nil?)
          visit.rename_required_series(old_rs_name, new_rs_name)
        end
      end

      visit.visit_type = 'imaging'
      visit.save

      print "#{index}.." if(index % 100 == 0)
    end
  end

  desc "Fix assignment indices in visit data"
  task :fix_assignment_indices => [:environment] do
    study = Study.find(2)
    next if study.nil?
   
    visits_count = study.visits.count

    puts "Attempting to fix assignment indices for #{visits_count} visits"
 
    study.visits.each_with_index do |visit, index|
      new_index = {}
      
      visit.required_series.each do |rs_name, data|
        next if data['image_series_id'].blank?

        new_index[data['image_series_id']] ||= []
        new_index[data['image_series_id']] << rs_name
      end

      visit.assigned_image_series_index = new_index
      visit.save

      print "#{index}.." if(index % 100 == 0)
    end
  end
end
