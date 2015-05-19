module Remote
  class ImagesSync
    def self.perform(remote_config = {})
      ImageSync.new(remote_config).perform!
    end

    def perform!
      # Look for priorities and sync the most important folders first
    end
  end
end
