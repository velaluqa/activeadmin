module Mongo
  class Restore
    class << self
      MONGORESTORE_ARGS = %w(host port db username password drop)

      def mongoid_configuration
        conf = Rails.configuration.mongoid.clients['default']
        fail 'No such mongoid configuration' if conf.nil?
        conf
      end

      def mongo_options
        conf = mongoid_configuration.clone
        if conf['hosts']
          fail 'Cannot handle multiple hosts.' if conf['hosts'].length > 1
          conf['host'], conf['port'] = conf.delete('hosts').first.split(':')
        end
        conf['db'] = conf.delete('database')
        conf
      end

      def format_argument(*args)
        key, value = args.flatten
        return unless value
        return "--#{key}" if value.is_a?(TrueClass)
        "--#{key}=#{value.to_s.shellescape}"
      end

      def arguments(options = {})
        mongo_options
          .merge(options.stringify_keys)
          .pick(MONGORESTORE_ARGS)
          .map(&method(:format_argument))
          .compact
      end

      def from_dir(dir, options = {})
        options = { drop: true }.merge(options)
        system_or_die("mongorestore #{arguments(options).join(' ')} #{dir.shellescape}")
      end
    end
  end
end
