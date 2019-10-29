FactoryBot.define do
  factory :notification do
    notification_profile_id { create(:notification_profile).id }
    resource_id { create(:visit, :without_notification_callbacks).id }
    resource_type 'Visit'
    user_id { create(:user).id }
    triggering_action 'create'

    # When building notifications with factory_girl, we do not want to
    # run the callbacks for instant notification emails.
    after(:build) do |notification|
      notification.version = notification.resource.versions.last

      class << notification
        def send_instant_notification_email
          true
        end
      end
    end
  end
end
