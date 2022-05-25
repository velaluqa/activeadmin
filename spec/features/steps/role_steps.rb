step 'a role :string with permissions:' do |title, permissions|
  role = FactoryBot.create(:role, title: title)
  permissions.to_a.each do |subject, activities|
    activities = activities.split(/, ?/)
    activities.each do |activity|
      unless Ability::ACTIVITIES[subject.constantize].include?(activity.to_sym)
        fail "Permission #{activity} not known for subject #{subject}"
      end
      role.add_permission(activity, subject)
    end
  end
end
