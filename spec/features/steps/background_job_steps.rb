step 'a background job :string for user :user_instance' do |name, user|
  create(:background_job, user: user, name: name)
end
