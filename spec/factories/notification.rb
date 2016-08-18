FactoryGirl.define do
  factory :notification do
    notification_profile_id { create(:notification_profile).id }
    resource_id { create(:visit).id }
    resource_type 'Visit'
    user_id { create(:user).id }
  end
end
