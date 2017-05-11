module Mongo
  class Dumper
    class << self
      MONGODUMP_ARGS = %w[host port db username password collection out].freeze

      def mongoid_configuration
        conf = Rails.configuration.mongoid.clients['default']
        raise 'No such mongoid configuration' if conf.nil?
        conf
      end

      def mongo_options
        conf = mongoid_configuration.clone
        raise 'Cannot handle multiple hosts.' if conf['hosts'].length > 1
        conf['db'] = conf.delete('database')
        conf['host'], conf['port'] = conf.delete('hosts').first.split(':')
        conf
      end

      def format_argument(*args)
        key, value = args.flatten
        return unless value
        return "--#{key}" if value.is_a?(TrueClass)
        "--#{key}=#{Shellwords.escape(value.to_s)}"
      end

      def arguments(options = {})
        mongo_options
          .merge(options.stringify_keys)
          .pick(MONGODUMP_ARGS)
          .map(&method(:format_argument))
          .compact
      end

      def rename_dir(options = {})
        raise 'No renaming target given' unless options[:dir]
        source = File.join(options[:out].to_s || '.', mongo_options['db'], '')
        target = File.join(options[:out].to_s || '.', options[:dir], '')
        system_or_die("rsync --remove-source-files -a #{source.shellescape} #{target.shellescape}")
        system_or_die("rmdir #{source.shellescape}")
      end

      def mongodump(options = {})
        system_or_die("mongodump #{arguments(options).join(' ')}")
        rename_dir(options) if options[:dir]
      end

      def dump(options = {})
        if options.key?(:collections)
          collections = Array[options.delete(:collections)].flatten
          collections.each do |collection|
            mongodump(options.merge(collection: collection))
          end
        else
          mongodump(options)
        end
      end
    end
  end
end
