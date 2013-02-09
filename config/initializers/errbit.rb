require 'openssl'

Airbrake.configure do |config|
  if File.exists?('/usr/share/ca-certificates/cacert.org/root.crt')    
    OpenSSL::X509::DEFAULT_CERT_FILE = '/usr/share/ca-certificates/cacert.org/root.crt'
  elsif File.exists?('/etc/ssl/certs/cacert.org.pem')
    OpenSSL::X509::DEFAULT_CERT_FILE = '/etc/ssl/certs/cacert.org.pem'
  end

  config.api_key = '63ff31e731dae289ad389b4fcafbbb00'
  config.host    = 'prof-maad.org'
  config.port    = 4435
  config.secure  = true
  config.use_system_ssl_cert_chain = true
end
