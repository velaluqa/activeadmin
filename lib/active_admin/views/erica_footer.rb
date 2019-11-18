module ActiveAdmin
  module Views
    # Overriding ActiveAdmin defaults.
    class EricaFooter < Component
      def build(_namespace)
        super(id: 'footer')

        para do
          text_node "ERICA v#{StudyServer::Application.config.erica_version.join('.')}, Copyright 2012-#{Time.now.year} "
          text_node helpers.link_to 'Pharmtrace klinische Entwicklung GmbH', 'http://www.pharmtrace.com', target: '_blank'
        end
      end
    end
  end
end
