class Remote
  class ImageSync
    include Logging

    attr_reader :remote

    def initialize(remote)
      @remote = Remote.new(remote)
    end

    def study_path_mappings
      remote.study_ids.mash do |id|
        [ERICA.image_storage_path.join(id), remote.image_storage_dir.join(id)]
      end
    end

    def perform
      study_path_mappings.each do |source, target|
        logger.info "syncing images: #{source} => #{remote.host}:#{target}"
        remote.mkdir_p(target)
        remote.rsync_to("#{source}/", target)
      end
    end

    def self.perform(remote)
      ImageSync.new(remote).perform
    end
  end
end
