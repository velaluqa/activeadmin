if Rails.env.production?
  require 'openssl'

  Airbrake.configure do |config|
    OpenSSL::X509.send(:remove_const, 'DEFAULT_CERT_FILE') # this is somewhat of a hack, but it is safe enough and gets rid of the annoying warning on statup
    if File.exists?('/usr/share/ca-certificates/cacert.org/root.crt')
      OpenSSL::X509::DEFAULT_CERT_FILE = '/usr/share/ca-certificates/cacert.org/root.crt'
    elsif File.exists?('/etc/ssl/certs/cacert.org.pem')
      OpenSSL::X509::DEFAULT_CERT_FILE = '/etc/ssl/certs/cacert.org.pem'
    end

    config.api_key = Rails.application.config.airbrake_api_key
    config.host    = 'prof-maad.org'
    config.port    = 4435
    config.secure  = true
    config.use_system_ssl_cert_chain = true
  end
end
