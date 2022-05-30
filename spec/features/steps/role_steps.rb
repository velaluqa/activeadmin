step 'a role :string with permissions:' do |title, permissions|
  role = FactoryBot.create(:role, title: title)
  permissions.to_a.each do |subject, activities|
    activities = activities.split(/, ?/)
    activities.each do |activity|
      role.add_permission(activity, subject)
    end
  end
end

step 'permission :string for :string was revoked' do |permission, role_name|
  role = Role.where(title: role_name).first
  activity, subject = permission.split(" ")
  unless Ability::ACTIVITIES[subject.constantize].include?(activity.to_sym)
    fail "Permission #{activity} not known for subject #{subject}"
  end
  role.remove_permission(activity, subject)
end
