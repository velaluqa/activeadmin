module ImageStorageCallbacks
  extend ActiveSupport::Concern

  included do
    after_create :create_image_storage
    after_update :move_image_storage
    after_destroy :remove_image_storage

    def create_image_storage
      return true if is_a?(Image)

      path = ERICA.image_storage_path.join(image_storage_path)

      make_image_storage_dir(path)
      make_image_storage_dir(path.join('__unassigned')) if is_a?(Patient)
    end

    def move_image_storage
      old = ERICA.image_storage_path.join(previous_image_storage_path)
      new = ERICA.image_storage_path.join(image_storage_path)
      move_image_storage_dir(old, new)
    end

    def remove_image_storage
      path = ERICA.image_storage_path.join(previous_image_storage_path)
      remove_image_storage_dir(path.join('__unassigned')) if is_a?(Patient)
      remove_image_storage_dir(path)
    end

    # Make a directory within ERICA image storage.
    #
    # @param [String,Pathname] path path to the directory
    #
    # @return [Boolean] success
    def make_image_storage_dir(path)
      FileUtils.mkdir_p(path.to_s)
    rescue SystemCallError => e
      Rails.logger.error "Failed to create image storage directory for #{self} at #{path}: #{e}"
      false
    end

    # Move directory within ERICA image storage.
    #
    # @param [String,Pathname] old directory to move
    # @param [String,Pathname] new new path of the directory
    #
    # @return [Boolean] success
    def move_image_storage_dir(old, new)
      FileUtils.mv(old, new)
    rescue SystemCallError => e
      Rails.logger.error "Failed to move image storage directory for #{self} from #{old} to #{new}: #{e}"
      false
    end

    # Remove directory within ERICA image storage.
    #
    # @param [String,Pathname] path directory to delete
    #
    # @return [Boolean] success
    def remove_image_storage_dir(path)
      FileUtils.rm_r(path)
    rescue SystemCallError => e
      Rails.logger.error "Failed to remove image storage for #{self} at #{path}: #{e}"
      false
    end

    # Returns the image storage path of the previous version for
    # update or delete operations.
    #
    # @return [String] previous image storage path
    def previous_image_storage_path
      return image_storage_path unless previous_version
      previous_version.image_storage_path
    end

    # Stub: Should return the models image storage path. Make sure
    # this method is overridden by any model including this concern.
    #
    # @return [String] image storage path
    def image_storage_path
      raise '#image_storage_path is not defined for model including ImageStorageCallbacks concern'
    end
  end
end
