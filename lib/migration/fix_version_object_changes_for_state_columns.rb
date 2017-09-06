module Migration
  class FixVersionObjectChangesForStateColumns
    class << self
      def run
        progress = ProgressBar.create(
          title: 'Visit#state',
          total: visit_state_versions.count,
          format: '%t |%B| %a / %E (%c / %C ~ %p%%)'
        )
        visit_state_versions.find_each do |version|
          was, becomes = version.object_changes['state']
          if was.is_a?(String)
            version.object_changes['state'][0] =
              Visit.state_sym_to_int(was.to_sym)
          end
          if becomes.is_a?(String)
            version.object_changes['state'][1] =
              Visit.state_sym_to_int(becomes.to_sym)
          end
          version.save
          progress.increment
        end
        progress = ProgressBar.create(
          title: 'Visit#mqc_state',
          total: visit_mqc_state_versions.count,
          format: '%t |%B| %a / %E (%c / %C ~ %p%%)'
        )
        visit_mqc_state_versions.find_each do |version|
          was, becomes = version.object_changes['mqc_state']
          if was.is_a?(String)
            version.object_changes['mqc_state'][0] =
              Visit.mqc_state_sym_to_int(was.to_sym)
          end
          if becomes.is_a?(String)
            version.object_changes['mqc_state'][1] =
              Visit.mqc_state_sym_to_int(becomes.to_sym)
          end
          version.save
          progress.increment
        end
        progress = ProgressBar.create(
          title: 'ImageSeries#state',
          total: image_series_state_versions.count,
          format: '%t |%B| %a / %E (%c / %C ~ %p%%)'
        )
        image_series_state_versions.find_each do |version|
          was, becomes = version.object_changes['state']
          if was.is_a?(String)
            version.object_changes['state'][0] =
              ImageSeries.state_sym_to_int(was.to_sym)
          end
          if becomes.is_a?(String)
            version.object_changes['state'][1] =
              ImageSeries.state_sym_to_int(becomes.to_sym)
          end
          version.save
          progress.increment
        end
      end

      def visit_state_versions
        Version
          .where(item_type: 'Visit')
          .where(
            'object_changes #>> \'{state,0}\' IN (?) OR object_changes #>> \'{state,1}\' IN (?)',
            Visit::STATE_SYMS,
            Visit::STATE_SYMS
          )
      end

      def visit_mqc_state_versions
        Version
          .where(item_type: 'Visit')
          .where(
            'object_changes #>> \'{mqc_state,0}\' IN (?) OR object_changes #>> \'{mqc_state,1}\' IN (?)',
            Visit::MQC_STATE_SYMS,
            Visit::MQC_STATE_SYMS
          )
      end

      def image_series_state_versions
        Version
          .where(item_type: 'ImageSeries')
          .where(
            'object_changes #>> \'{state,0}\' IN (?) OR object_changes #>> \'{state,1}\' IN (?)',
            ImageSeries::STATE_SYMS,
            ImageSeries::STATE_SYMS
          )
      end
    end
  end
end
