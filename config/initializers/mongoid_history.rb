require_dependency 'mongoid_history_tracker.rb' if Rails.env.development?

Mongoid::History.tracker_class_name = :mongoid_history_tracker
Mongoid::History.current_user_method = :current_user

