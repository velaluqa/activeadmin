module ActiveAdminCommentPaperTrailPatch
  extend ActiveSupport::Concern

  included do
    has_paper_trail class_name: 'Version'

    belongs_to :user, foreign_key: :author_id

    scope :searchable, -> { joins(:user).select(<<~SELECT) }
      NULL::integer AS study_id,
      NULL::varchar AS study_name,
      concat(active_admin_comments.resource_type, ' Comment by ', users.name) AS text,
      active_admin_comments.id::varchar AS result_id,
      'Comment'::varchar AS result_type
    SELECT

    def self.granted_for(options = {})
      activities = Array(options[:activity]) + Array(options[:activities])
      user = options[:user] || raise("Missing 'user' option")
      # TODO: Restrict access only to those comments that are for
      # resources the user can access. This might incorporate the need
      # for caching columns for the scoping permissions of roles.
      all
    end

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

    def versions_item_name
      return name if respond_to?(:name)

      to_s
    end
  end
end
