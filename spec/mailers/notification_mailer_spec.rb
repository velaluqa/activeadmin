RSpec.describe NotificationMailer do
  before(:each) do
    Rails.application.routes.default_url_options[:host] = 'test.de'
  end

  describe 'instant_notification_email' do
    let(:template) do
      create(
        :email_template,
        email_type: 'NotificationProfile',
        template: <<TPL.gsub("\n", "\r\n")
Dear {{ user.name }},

<table>
  <thead>
    <th>Resource Type</th>
    <th>Resource</th>
    <th></th>
  </thead>
  {% for notification in notifications %}
  <tr>
    <td>{{ notification.resource.class_name }}</td>
    <td>{{ notification.resource.visit_type }}({{ notification.resource.visit_number }})</td>
    <td>{{ notification.resource | link:'Open in ERICA' }}</td>
  </tr>
  {% endfor %}
</table>

Kind Regards,

Your Pharmtrace Team
TPL
      )
    end
    let(:user) { create(:user, email: 'some@mail.com') }
    let(:profile) { create(:notification_profile, email_template: template) }
    let(:notification) { create(:notification, notification_profile: profile) }
    let(:mail) do
      NotificationMailer.instant_notification_email(notification)
    end

    it 'renders the subject' do
      expect(mail.subject).to eql(notification.notification_profile.title)
    end

    it 'renders the receiver email' do
      expect(mail.to).to eql([notification.user.email])
    end

    it 'renders the sender email' do
      expect(mail.from).to eql(['noreply@pharmtrace.com'])
    end

    it 'greets the user by name' do
      expect(mail.body.encoded).to match(notification.user.name)
    end

    it 'lists all notification resource types' do
      expect(mail.body.encoded).to match('Visit')
    end

    it 'lists all notification resources' do
      expect(mail.body.encoded).to include(notification.resource.to_s)
    end

    it 'links to the changed resource' do
      expect(mail.body.encoded).to include("test.de/admin/visits/#{notification.resource.id}")
    end

    it 'contains correct paragraphs' do
      expect(mail.body.encoded).to include('<p>Kind Regards,</p>')
    end
  end

  describe 'throttled_notification_email' do
    let(:template) do
      create(
        :email_template,
        email_type: 'NotificationProfile',
        template: <<TPL
Dear {{ user.name }},

<table>
  <thead>
    <th>Resource Type</th>
    <th>Resource</th>
    <th></th>
  </thead>
  {% for notification in notifications %}
  <tr>
    <td>{{ notification.resource.class_name }}</td>
    <td>{{ notification.resource.visit_type }}({{ notification.resource.visit_number }})</td>
    <td>{{ notification.resource | link:'Open in ERICA' }}</td>
  </tr>
  {% endfor %}
</table>

Kind Regards,

Your Pharmtrace Team
TPL
      )
    end
    let(:user) { create(:user, email: 'some@mail.com') }
    let(:profile) { create(:notification_profile, email_template: template) }
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

    it 'links to the changed resource' do
      notifications.each do |notification|
        expect(mail.body.encoded).to include("test.de/admin/visits/#{notification.resource.id}")
      end
    end

    it 'contains correct paragraphs' do
      expect(mail.body.encoded).to include('<p>Kind Regards,</p>')
    end
  end

  describe 'sending' do
    let(:template) do
      create(
        :email_template,
        email_type: 'NotificationProfile',
        template: <<TPL
Dear {{ user.name }},

<table>
  <thead>
    <th>Resource Type</th>
    <th>Resource</th>
    <th></th>
  </thead>
  {% for notification in notifications %}
  <tr>
    <td>{{ notification.resource.class_name }}</td>
    <td>{{ notification.resource.visit_type }}({{ notification.resource.visit_number }})</td>
    <td>{{ notification.resource | link:'Open in ERICA' }}</td>
  </tr>
  {% endfor %}
</table>

Kind Regards,

Your Pharmtrace Team
TPL
      )
    end
    let(:user) { create(:user, email: 'some@mail.com') }
    let(:profile) { create(:notification_profile, email_template: template) }
    let(:notifications) do
      create_list(:notification, 3, notification_profile: profile)
    end

    before(:each) do
      NotificationMailer.throttled_notification_email(
        user, profile, notifications
      ).deliver_now
    end

    it 'marks the notification as send' do
      expect(ActionMailer::Base.deliveries).not_to be_empty
      notifications.each do |notification|
        notification.reload
        expect(notification.email_sent_at).not_to be_nil
      end
    end
  end
end
