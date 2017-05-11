module ActiveAdminCommentPaperTrailPatch
  extend ActiveSupport::Concern

  included do
    has_paper_trail class_name: 'Version'
  end

  module InstanceMethods
    def resource_name
      if resource.nil? || !resource.respond_to?(:name)
        "#{resource_type} #{resource_id}"
      else
        "#{resource_type} '#{resource.name}'"
      end
    end

    def name
      "Comment on #{resource_name}"
    end
  end
end
