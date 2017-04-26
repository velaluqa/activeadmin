namespace :erica do
  desc 'Reset the domino_unid of all images series and visits in the specified study'
  task :reset_domino_unids, [:study_id] => [:environment] do |t, args|
    if(args[:study_id].nil?)
      puts "No study id given, not resetting."
      next
    end
    study_id = args[:study_id]
    study = Study.find(study_id)

    print 'Deactivating after_commit Domino sync callback...'
    ImageSeries.skip_callback :commit, :after, :ensure_domino_document_exists
    Visit.skip_callback :commit, :after, :ensure_domino_document_exists
    puts 'done'

    count = 0

    puts "Resetting #{study.image_series.count} image series..."
    study.image_series.find_each do |image_series|
      image_series.domino_unid = nil
      image_series.save

      count += 1
      print count.to_s+'..' if(count %100 == 0)
    end
    puts
    puts 'done'

    count = 0
    puts "Resetting #{study.visits.count} visits..."
    study.visits.find_each do |visit|
      visit.domino_unid = nil
      visit.save

      count += 1
      print count.to_s+'..' if(count %100 == 0)
    end
    puts
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

    count = 0
    puts "Syncing #{study.centers.count} centers..."
    study.centers.find_each do |center|
      center.domino_sync

      count += 1
      print count.to_s+'..' if(count %100 == 0)
    end
    puts
    puts 'done'

    count = 0
    puts "Syncing #{study.patients.count} patients..."
    study.patients.find_each do |patient|
      patient.domino_sync

      count += 1
      print count.to_s+'..' if(count %100 == 0)
    end
    puts
    puts 'done'

    count = 0
    puts "Syncing #{study.image_series.count} image series..."
    study.image_series.find_each do |image_series|
      image_series.domino_sync

      count += 1
      print count.to_s+'..' if(count %100 == 0)
    end
    puts
    puts 'done'

    count = 0
    puts "Syncing #{study.visits.count} visits..."
    study.visits.find_each do |visit|
      visit.domino_sync
      visit.required_series_objects.each do |required_series|
        required_series.domino_sync
      end

      count += 1
      print count.to_s+'..' if(count %100 == 0)
    end
    puts
    puts 'done'
  end
end
