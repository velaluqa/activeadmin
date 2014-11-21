require 'logger'

timestamp = Time.now.strftime('%Y-%m-%d %H:%M:%S')
version_string = StudyServer::Application.config.erica_version.join('.')
Rails.logger.info "[#{timestamp}]::VERSION ERICA version #{version_string} started"
