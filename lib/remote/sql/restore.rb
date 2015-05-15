module Sql
  class Restore
    class << self
      PSQL_ARGS = %w(host port dbname username file)

      def database_configuration
        conf = Rails.configuration.database_configuration[Rails.env]
        fail "No such database configuration for #{Rails.env}" if conf.nil?
        conf
      end

      def psql_options(options = {})
        options = database_configuration.merge(options.stringify_keys)
        options['dbname'] = options.delete('database')
        options.pick(PSQL_ARGS)
      end

      def psql_args(options = {})
        options = psql_options(options)
        options.map { |key, val| "--#{key}=#{Shellwords.escape(val.to_s)}" }
      end

      def psql_password
        database_configuration['password']
      end

      def psql_password_env
        return '' unless psql_password
        "PGPASSWORD=#{Shellwords.escape(psql_password)} "
      end

      def psql(options = {})
        system("#{psql_password_env}psql #{psql_args(options).join(' ')}")
      end

      def from_file(filename)
        psql(file: filename)
      end
    end
  end
end
