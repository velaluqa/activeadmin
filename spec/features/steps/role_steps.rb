step 'a role :string with permissions:' do |title, permissions|
  role = FactoryGirl.create(:role, title: title)
  permissions.to_a.each do |subject, activities|
    activities = activities.split(/, ?/)
    activities.each do |activity|
      role.add_permission(activity, subject)
    end
  end
end
