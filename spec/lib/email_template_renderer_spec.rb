require 'email_template_renderer'

describe EmailTemplateRenderer do
  describe '::render' do
    let!(:user) { create(:user) }
    let!(:visit) { create(:visit, visit_type: 'foo_type') }
    let!(:notification) do
      Notification.new(
        triggering_action: 'create',
        user: user,
        resource: visit,
        version: visit.versions.last
      )
    end
    let!(:template) do
      EmailTemplate.new(
        email_type: 'NotificationProfile',
        template: <<TPL
My Visit Type: {{ notifications[0].resource.visit_type }}

My Visit Type: {{ notifications[0].resource.visit_typ }}

Date: {{ notifications[0].resource.created_at }}
TPL
      )
    end
    let!(:renderer) do
      EmailTemplateRenderer.new(
        template,
        user: user,
        notifications: [notification]
      )
    end

    it 'renders existing variable values' do
      expect(renderer.render).to include "<p>My Visit Type: foo_type</p>"
      expect(renderer.render).to include "<p>Date: #{visit.created_at}</p>"
    end

    it 'renders empty string for missing variable' do
      expect(renderer.render).to include('<p>My Visit Type: </p>')
    end

    it 'raises `SyntaxError`' do
      expect {
        template = EmailTemplate.new(
          email_type: 'NotificationProfile',
          template: 'My Visit Type: {{ '
        )
        EmailTemplateRenderer.new(
          template,
          user: user,
          notifications: [notification]
        ).render
      }.to raise_error EmailTemplateRenderer::Error
    end
  end

  describe '::render_preview' do
    it 'renders `NotificationProfile` type templates' do
      user = create(:user)
      visit = create(:visit, visit_type: 'foo_type')
      result = EmailTemplateRenderer.render_preview(
        type: 'NotificationProfile',
        user: user,
        subject: visit,
        template: <<TPL
My Visit Type: {{ notifications[0].resource.visit_type }}

Date: {{ notifications[0].resource.created_at }}
TPL
      )
      expect(result).to include "<p>My Visit Type: foo_type</p><p>Date: #{visit.created_at}</p>"
    end

    it 'raises `CompilationError`' do
      user = create(:user)
      visit = create(:visit, visit_type: 'foo_type')
      expect {
        EmailTemplateRenderer.render_preview(
          type: 'NotificationProfile',
          user: user,
          subject: visit,
          template:
            'My Visit Type: {{ notifications[0].resource.visit_typ }}'
        )
      }.to raise_error EmailTemplateRenderer::Error
    end

    it 'raises `SyntaxError`' do
      user = create(:user)
      visit = create(:visit, visit_type: 'foo_type')
      expect {
        EmailTemplateRenderer.render_preview(
          type: 'NotificationProfile',
          user: user,
          subject: visit,
          template:
            'My Visit Type: {{ '
        )
      }.to raise_error EmailTemplateRenderer::Error
    end
  end
end
