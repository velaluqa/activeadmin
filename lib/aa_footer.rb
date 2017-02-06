class PharmTraceERICAFooter < ActiveAdmin::Component
  def build
    super(id: 'footer')

    para do
      text_node "ERICA v#{StudyServer::Application.config.erica_version.join('.')}, Copyright 2012-#{Time.now.year} "
      text_node helpers.link_to 'Pharmtrace klinische Entwicklung GmbH', 'http://www.pharmtrace.com', target: '_blank'
    end
  end
end
