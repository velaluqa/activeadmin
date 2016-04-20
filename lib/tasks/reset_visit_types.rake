namespace :erica do
  desc "Reset visit types and required series assignments for Tasq"
  task :reset_tasq_visits => :environment do
    tasq = Study.where(:name => '340047').first
    next if tasq.nil?
    pp tasq
    
    visits = tasq.visits
    puts visits.count

    visits.each do |visit|
      visit.assigned_image_series_index = {}
      visit.required_series = {}
s      visit.visit_type = nil
      visit.save
    end
  end
end
