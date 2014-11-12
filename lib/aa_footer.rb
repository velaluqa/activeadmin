class PharmTraceERICAFooter < ActiveAdmin::Component
  def build
    super(id: 'footer')

    if(Rails.application.config.is_erica_remote)
      title = "ERICA Remote"
    else
      title = "ERICA"
    end

    para "#{title} v#{StudyServer::Application.config.erica_version.join('.')}, Copyright 2012-#{Time.now.year} Pharmtrace klinische Entwicklung GmbH"
  end
end
