require 'email_template_renderer'

describe EmailTemplateRenderer do
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
