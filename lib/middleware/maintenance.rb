require 'rack'

module Middleware
  class Maintenance
    MAINTENANCE_PAGE = begin
      content = File.read("/app/public/maintenance.html")
      [
        503,
        {
          'Content-Type' => 'text/html',
          'Content-Length' => content.bytesize.to_s
        },
        [content]
      ]
    end

    attr_reader :app

    def initialize(app)
      @app = app
    end

    def call(env)
      if maintenance? && !erica_admin?(env)
        MAINTENANCE_PAGE
      else
        app.call(env)
      end
    end

    private

    def erica_admin?(env)
      env["HTTP_USER_AGENT"] =~ /ericaadmin/
    end

    def flag_file
      "/app/.maintenance"
    end

    def maintenance?
      File.exist?(flag_file) && File.read(flag_file).strip == "true"
    end
  end
end
