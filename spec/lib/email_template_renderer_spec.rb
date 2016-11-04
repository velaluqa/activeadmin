require 'email_template_renderer'

describe EmailTemplateRenderer do
  it 'renders with local variables' do
  end

  describe '::render_preview' do
    it 'renders `NotificationProfile` type templates' do
      user = create(:user)
      visit = create(:visit, visit_type: 'foo_type')
      result = EmailTemplateRenderer.render_preview(
        type: 'NotificationProfile',
        user: user,
        subject: visit,
        template:
          'My Visit Type: <%= notifications.first.resource.visit_type %>'
      )
      expect(result).to eq 'My Visit Type: foo_type'
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
            'My Visit Type: <%= notifications.first.resource.visit_typ %>'
        )
      }.to raise_error EmailTemplateRenderer::CompilationError
    end
  end
end
