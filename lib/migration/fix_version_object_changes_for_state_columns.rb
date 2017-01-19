module Migration
  class FixVersionObjectChangesForStateColumns
    class << self
      def run
        visit_state_versions.find_each do |version|
          version.object_changes['state'][1] =
            Visit.state_sym_to_int(version.object_changes['state'][1].to_sym)
          version.save
        end
        visit_mqc_state_versions.find_each do |version|
          version.object_changes['mqc_state'][1] =
            Visit.mqc_state_sym_to_int(version.object_changes['mqc_state'][1].to_sym)
          version.save
        end
        image_series_state_versions.find_each do |version|
          version.object_changes['state'][1] =
            ImageSeries.state_sym_to_int(version.object_changes['state'][1].to_sym)
          version.save
        end
      end

      def visit_state_versions
        Version
          .where(item_type: 'Visit')
          .where('"versions"."object_changes"::jsonb ? \'state\'')
      end

      def visit_mqc_state_versions
        Version
          .where(item_type: 'Visit')
          .where('"versions"."object_changes"::jsonb ? \'mqc_state\'')
      end

      def image_series_state_versions
        Version
          .where(item_type: 'ImageSeries')
          .where('"versions"."object_changes"::jsonb ? \'state\'')
      end
    end
  end
end
