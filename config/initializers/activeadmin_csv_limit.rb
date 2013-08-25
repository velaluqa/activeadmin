# https://github.com/gregbell/active_admin/issues/346

module ActiveAdmin
  class ResourceController < BaseController
    module DataAccess
      def max_csv_records
        1_000_000
      end
    end
  end
end
