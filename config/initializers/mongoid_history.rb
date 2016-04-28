# TODO: Remove if all systems have been migrated successfully.
if File.exist?(Rails.root.join('config/mongoid.yml'))
  require 'legacy/models/mongoid_history_tracker'

  Mongoid::History.tracker_class_name = 'Legacy::MongoidHistoryTracker'
  Mongoid::History.current_user_method = :current_user
end
