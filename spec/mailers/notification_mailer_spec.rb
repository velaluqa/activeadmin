RSpec.describe NotificationMailer do
  describe 'throttled_notification_email' do
    before(:each) do
      Rails.application.routes.default_url_options[:host] = 'test.de'
    end

    let(:user) { create(:user, email: 'some@mail.com') }
    let(:profile) { create(:notification_profile) }
    let(:notifications) do
      create_list(:notification, 3, notification_profile: profile)
    end
    let(:mail) do
      NotificationMailer.throttled_notification_email(
        user, profile, notifications
      )
    end

    it 'renders the subject' do
      expect(mail.subject).to eql(profile.title)
    end

    it 'renders the receiver email' do
      expect(mail.to).to eql([user.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eql(['noreply@pharmtrace.com'])
    end

    it 'greets the user by name' do
      expect(mail.body.encoded).to match(user.name)
    end

    it 'lists all notification resource types' do
      expect(mail.body.encoded).to match('Visit')
    end

    it 'lists all notification resources' do
      notifications.each do |notification|
        expect(mail.body.encoded).to include(notification.resource.to_s)
      end
    end

    it 'links to the changed resource' do
      notifications.each do |notification|
        expect(mail.body.encoded).to include("test.de/admin/visits/#{notification.resource.id}")
      end
    end
  end
end
