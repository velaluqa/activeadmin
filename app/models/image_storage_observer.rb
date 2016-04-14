# TODO: Move functionality into ActiveSupport::Concerns or work with
# Trailblazer to enhance the applications architecture.
class ImageStorageObserver < ActiveRecord::Observer
  observe :study, :center, :patient, :visit, :image_series, :image

  # this is actually a hack
  # this should be done like so:
  ## after_commit :create_image_storage_path, :on => :create
  # but that syntax is not available in observers
  # so we have to hack our way around it by using the protected method transaction_include_action?
  # my heart weeps
  def after_commit(model)
    # since observers are a singleton class, initializers are apparently not called properly
    # thats why we have to do this here
    if(@image_storage_root.nil?)
      @image_storage_root = Rails.application.config.image_storage_root
      unless(@image_storage_root.end_with?('/'))
        @image_storage_root += '/'
      end
    end

    #puts "AFTER COMMIT HOOK FOR"
    #pp model
    # TODO: Refactor! The protected function should not be called!
    if model.send(:transaction_include_any_action?, [:create])
      #puts "CREATE-------------------"
      create_image_storage_path(model)
    end
    # TODO: Refactor! The protected function should not be called!
    if model.send(:transaction_include_any_action?, [:update])
      #puts "UPDATE-------------------"
      move_image_storage_path(model)
    end
    # TODO: Refactor! The protected function should not be called!
    if model.send(:transaction_include_any_action?, [:destroy])
      #puts "DESTROY-------------------"
      remove_image_storage_path(model)
    end
  end

  def create_image_storage_path(model)
    return true if model.is_a?(Image) # we don't create images, they are uploaded using the Image Uploader

    begin
      FileUtils.mkdir(@image_storage_root + model.image_storage_path)
    rescue SystemCallError => e
      Rails.logger.error "Failed to create image storage for #{model} at #{@image_storage_root + model.image_storage_path}: #{e}"
      return false
    end

    if(model.is_a?(Patient))
      begin
        FileUtils.mkdir(@image_storage_root + model.image_storage_path + '/__unassigned')
      rescue SystemCallError => e
        Rails.logger.error "Failed to create image storage for #{model} at #{@image_storage_root + model.image_storage_path + '/__unassigned'}: #{e}"
        return false
      end
    end

    true
  end

  def move_image_storage_path(model)
    previous_image_storage_path = @image_storage_root + model.previous_image_storage_path
    new_image_storage_path = @image_storage_root + model.image_storage_path

    if(previous_image_storage_path != new_image_storage_path)
      begin
        FileUtils.mv(previous_image_storage_path, new_image_storage_path)
      rescue SystemCallError => e
        Rails.logger.error "Failed to move data for #{model} from #{previous_image_storage_path} to #{new_image_storage_path}: #{e}"
        return false
      end
    end

    true
  end

  def remove_image_storage_path(model)
    previous_image_storage_path = @image_storage_root + model.previous_image_storage_path

    if(model.is_a?(Patient))
      begin
        FileUtils.rm_r(previous_image_storage_path + '/__unassigned')
      rescue SystemCallError => e
        Rails.logger.error "Failed to remove image storage for #{model} at #{previous_image_storage_path + '/__unassigned'}: #{e}"
        return false
      end
    end
    
    begin
      # because we delete dependent records for patient and everything below it, the after_commit callbacks get called in the wrong order
      # since its all happening inside the same transaction
      # so the image will be deleted after the image_series
      # therefore, when we attempt to rmdir the image series folder here, it will fail because there are still images inside
      # hence: rm -r
      if(model.is_a?(Patient) || model.is_a?(Visit) || model.is_a?(ImageSeries))
        FileUtils.rm_r(previous_image_storage_path)
      else
        FileUtils.rmdir(previous_image_storage_path)
      end
    rescue SystemCallError => e
      Rails.logger.error "Failed to remove image storage for #{model} at #{previous_image_storage_path}: #{e}"
      return false
    end

    true
  end
end
