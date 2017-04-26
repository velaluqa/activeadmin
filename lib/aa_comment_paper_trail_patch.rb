module ActiveAdminCommentPaperTrailPatch
  extend ActiveSupport::Concern

  included do
    has_paper_trail class_name: 'Version'
  end

  module InstanceMethods
    def resource_name
      if(self.resource.nil? or not self.resource.respond_to?(:name))
        "#{self.resource_type} #{self.resource_id}"
      else
        "#{self.resource_type} '#{self.resource.name}'"
      end
    end

    def name
      "Comment on #{resource_name}"
    end
  end
end
