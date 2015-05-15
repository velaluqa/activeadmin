module Mongo
  class Dumper
    class << self
      MONGODUMP_ARGS = %w(host port db username password collection out)

      def mongoid_configuration
        conf = Rails.configuration.mongoid.sessions['default']
        fail 'No such mongoid configuration' if conf.nil?
        conf
      end

      def mongo_options
        conf = mongoid_configuration.clone
        fail 'Cannot handle multiple hosts.' if conf['hosts'].length > 1
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
          .map { |key, val| "--#{key}=#{Shellwords.escape(val.to_s)}" }
      end

      def rename_dir(options = {})
        fail 'No renaming target given' unless options[:dir]
        source = File.join(options[:out].to_s || '.', mongo_options['db'], '')
        target = File.join(options[:out].to_s || '.', options[:dir], '')
        system("rsync --remove-source-files -a #{Shellwords.escape(source)} #{Shellwords.escape(target)}")
        system("rmdir #{Shellwords.escape(source)}")
      end

      def mongodump(options = {})
        system("mongodump #{arguments(options).join(' ')}")
        rename_dir(options) if options[:dir]
      end

      def dump_collections(options = {})
        fail 'Missing \'collection\' option' unless options[:collections]
        collections = options.delete(:collections)
        collections.each do |collection|
          dump_collection(collection, options)
        end
      end

      def dump_collection(collection, options = {})
        dump(options.merge(collection: collection))
      end

      def dump(options = {})
        mongodump(options)
      end
    end
  end
end
