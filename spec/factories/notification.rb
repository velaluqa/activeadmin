FactoryGirl.define do
  factory :notification do
    notification_profile_id { create(:notification_profile).id }
    resource_id { create(:visit).id }
    resource_type 'Visit'
    user_id { create(:user).id }

    # When building notifications with factory_girl, we do not want to
    # run the callbacks for instant notification emails.
    after(:build) do |notification|
      class << notification
        def send_instant_notification_email
          true
        end
      end
    end
  end
end
