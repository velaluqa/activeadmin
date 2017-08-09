module Migration
  class VacuumFull # :nodoc:
    class << self
      def run
        ActiveRecord::Base.connection.execute('VACUUM FULL;')
      end
    end
  end
end
