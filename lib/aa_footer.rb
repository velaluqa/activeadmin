class PharmTraceERICAFooter < ActiveAdmin::Component
  def build
    super(id: 'footer')

    para "ERICA v#{StudyServer::Application.config.erica_version.join('.')}, Copyright #{Time.now.year} Pharmtrace klinische Entwicklung GmbH"
  end
end
