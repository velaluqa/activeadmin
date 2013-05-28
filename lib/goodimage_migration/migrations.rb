require 'goodimage_migration/models'

module GoodImageMigration
  def self.migrate_study(goodimage_study_id)
    Rails.logger.info "Attempting migration for GoodImage study with ID = #{goodimage_study_id}"

    goodimage_study = GoodImage::Study.get(goodimage_study_id)
    if(goodimage_study.nil?)
      Rails.logger.fatal "Could not find the study in GoodImage, aborting!"
      return false
    end

    Rails.logger.info "Found the study in GoodImage, starting migration..."
    Rails.logger.debug "GoodImage Study: #{goodimage_study.inspect}"

    erica_study = nil
    migration_mapping = Migration::Mapping.first(:type => 'study', :source_id => goodimage_study_id)
    if(migration_mapping)
      erica_study_id = migration_mapping.target_id
      Rails.logger.info "Found an existing migration mapping for this study, ERICA study has ID #{erica_study_id}"
      unless(migration_mapping.update_required?)
        Rails.logger.info "ERICA study is up to date, no migration required."
        return true
      end

      erica_study = Study.where(:id => erica_study_id).first
      if(erica_study.nil?)
        Rails.logger.warning "Could not find existing study in ERICA, creating a new one..."
      else
        Rails.logger.info "Found the existing study in ERICA, updating values..."
        Rails.logger.debug "Existing ERICA Study: #{erica_study.inspect}"
      end
    else
      Rails.logger.info "No existing migration mapping for this study, creating new study in ERICA..."
    end

    if(erica_study.nil?)
      erica_study = Study.new
    end

    erica_study.name = goodimage_study.internal_id

    Rails.logger.debug "Created/Updated ERICA Study: #{erica_study.inspect}"

    unless(erica_study.save)
      Rails.logger.fatal "Failed to save ERICA study, aborting"
      return false
    end

    if(migration_mapping.nil?)
      migration_mapping = Migration::Mapping.create(:type => 'study', :source_id => goodimage_study.id, :target_id => erica_study.id, :migration_timestamp => goodimage_study.modification_timestamp)
    else
      migration_mapping.migration_timestamp = goodimage_study.modification_timestamp
    end

    return migration_mapping.save
  end
end
