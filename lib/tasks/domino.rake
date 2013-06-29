namespace :erica do
  desc 'Reset the domino_unid of all images series and visits in the specified study'
  task :reset_domino_unids, [:study_id] => [:environment] do |t, args|
    if(args[:study_id].nil?)
      puts "No study id given, not resetting."
      next
    end
    study_id = args[:study_id]
    study = Study.find(study_id)

    print "Resetting #{study.image_series.count} image series..."
    study.image_series.each do |image_series|
      image_series.domino_unid = nil
      image_series.save
    end
    puts 'done'

    print "Resetting #{study.visits.count} visits..."
    study.visits.each do |visit|
      visit.domino_unid = nil
      visit.save
    end    
    puts 'done'
  end

  desc 'Force a Domino resync of all domino-connected resources in the specified study'
  task :full_domino_sync, [:study_id] => [:environment] do |t, args|
    if(args[:study_id].nil?)
      puts "No study id given, not syncing."
      next
    end
    study_id = args[:study_id]
    study = Study.find(study_id)
    
    print "Syncing #{study.centers.count} centers..."
    study.centers.each do |center|
      center.ensure_domino_document_exists
    end
    puts 'done'

    print "Syncing #{study.patients.count} patients..."
    study.patients.each do |patient|
      patient.ensure_domino_document_exists
    end
    puts 'done'

    print "Syncing #{study.image_series.count} image series..."
    study.image_series.each do |image_series|
      image_series.ensure_domino_document_exists
    end
    puts 'done'

    print "Syncing #{study.visits.count} visits..."
    study.visits.each do |visit|
      visit.ensure_domino_document_exists
      visit.domino_sync_required_series
    end
    puts 'done'
  end
end
