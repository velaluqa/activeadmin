require 'git_config_repository'

ActiveAdmin.register Version do
  menu(
    label: 'Audit Trail',
    parent: 'versions',
    priority: 0,
    if: -> { can?(:read, Version) }
  )

  config.comments = false
  config.batch_actions = false

  actions :index, :show

  filter :created_at

  filter :item_type, as: :select, collection: { 'Case' => 'Case',
                                                'Center' => 'Center',
                                                'Form' => 'Form',
                                                'Image' => 'Image',
                                                'ImageSeries' => 'ImageSeries',
                                                'RequiredSeries' => 'RequiredSeries',
                                                'Patient' => 'Patient',
                                                'Role' => 'Role',
                                                'Session' => 'Session',
                                                'Study' => 'Study',
                                                'User' => 'User',
                                                'Visit' => 'Visit' }.merge(Rails.application.config.is_erica_remote ? { 'Comment' => 'ActiveAdmin::Comment' } : {}).sort

  filter :whodunnit, label: 'User', as: :select, collection: proc { User.all }
  filter :event, as: :check_boxes, collection: %w[create update destroy]

  controller do
    def max_csv_records
      1_000_000
    end

    def scoped_collection
      association_chain = end_of_association_chain.includes(:item)

      return association_chain if params[:audit_trail_view_type].nil? || params[:audit_trail_view_id].nil?

      case params[:audit_trail_view_type]
      when 'study' then association_chain.for_study(params[:audit_trail_view_id])
      when 'center' then association_chain.for_center(params[:audit_trail_view_id])
      when 'patient' then association_chain.for_patient(params[:audit_trail_view_id])
      when 'visit' then association_chain.for_visit(params[:audit_trail_view_id])
      when 'image_series' then association_chain.for_image_series(params[:audit_trail_view_id])
      when 'image' then association_chain.for_image(params[:audit_trail_view_id])
      when 'role' then association_chain.for_role(params[:audit_trail_view_id])
      when 'user' then association_chain.for_user(params[:audit_trail_view_id])
      else association_chain
      end.accessible_by(current_ability)
    end

    # TODO: #2237 - Refactor audit trail via decorators
    def self.classify_event(version)
      return version.event if version.changeset.nil?
      c = version.changeset

      event_symbol = version.event
      if event_symbol == 'update' && c.keys == ['domino_unid']
        return :domino_unid_change
      end

      begin
        item_class = version.item_type.constantize
        if item_class.respond_to?(:classify_audit_trail_event)
          event_symbol = item_class.classify_audit_trail_event(c) || event_symbol
        end
      rescue NameError
      end

      event_symbol
    end

    def self.event_title_and_severity(item_type, event_symbol)
      title = nil
      severity = nil
      begin
        item_class = item_type.constantize
        if item_class.respond_to?(:audit_trail_event_title_and_severity)
          title, severity = item_class.audit_trail_event_title_and_severity(event_symbol)
        end
      rescue NameError => e
        pp e
      end

      if ['create', 'update', 'destroy', :domino_unid_change].include?(event_symbol)
        case event_symbol
        when 'create' then severity ||= nil
        when 'update' then severity ||= :warning
        when 'destroy' then severity ||= :error
        when :domino_unid_change
          title = 'Domino UNID Change'
          severity = :ok
        end
      end

      title ||= event_symbol.to_s.humanize

      [title, severity]
    end

    def audit_trail_resource
      return nil if params[:audit_trail_view_type].blank? || params[:audit_trail_view_id].blank?

      result = case params[:audit_trail_view_type]
               when 'case' then Case.where(id: params[:audit_trail_view_id].to_i).first
               when 'patient' then Patient.where(id: params[:audit_trail_view_id].to_i).first
               when 'form' then Form.where(id: params[:audit_trail_view_id].to_i).first
               when 'role' then Role.where(id: params[:audit_trail_view_id].to_i).first
               when 'user' then User.where(id: params[:audit_trail_view_id].to_i).first
               when 'session' then Session.where(id: params[:audit_trail_view_id].to_i).first
               when 'study' then Study.where(id: params[:audit_trail_view_id].to_i).first
               when 'form_answer' then FormAnswer.where(id: params[:audit_trail_view_id]).first
               when 'center' then Center.where(id: params[:audit_trail_view_id]).first
               when 'visit' then Visit.where(id: params[:audit_trail_view_id]).first
               when 'image_series' then ImageSeries.where(id: params[:audit_trail_view_id]).first
               when 'image' then Image.where(id: params[:audit_trail_view_id]).first
               end

      result
    end
  end

  action_item :edit, only: :index do
    resource = controller.audit_trail_resource
    status_tag(params[:audit_trail_view_type] + ': ' + (resource.respond_to?(:name) ? resource.name : '<' + resource.id.to_s + '>'), class: 'error audit_trail_indicator') unless resource.nil?
  end

  index(:pagination_total => false) do
    selectable_column
    column 'Timestamp', :created_at
    column :item_type, sortable: :item_type do |version|
      case version.item_type
      when 'ActiveAdmin::Comment' then 'Comment'
      else version.item_type
      end
    end
    column :item do |version|
      auto_link(version.item)
    end
    column :event do |version|
      event = Admin::VersionsController.classify_event(version)
      event_title, event_severity = Admin::VersionsController.event_title_and_severity(version.item_type, event)
      status_tag(event_title, class: event_severity.to_s)
    end
    column :user, sortable: :whodunnit do |version|
      if version.whodunnit.blank?
        'System'
      else
        auto_link(User.find_by_id(version.whodunnit.to_i))
      end
    end

    actions
  end

  show do |version|
    attributes_table do
      row :created_at
      row :item_type do
        case version.item_type
        when 'ActiveAdmin::Comment' then 'Comment'
        else version.item_type
        end
      end
      row :item do
        auto_link(version.item)
      end
      row :event do
        event = Admin::VersionsController.classify_event(version)
        event_title, event_severity = Admin::VersionsController.event_title_and_severity(version.item_type, event)
        status_tag(event_title, class: event_severity.to_s)
      end
      row :user do
        if version.whodunnit.blank?
          'System'
        else
          auto_link(User.find_by_id(version.whodunnit.to_i))
        end
      end
      if version.event == 'destroy'
        row :record do
          render 'admin/versions/object', object: version.object, item_type: version.item_type.constantize
        end
      else
        row :changes do
          unless version.changeset.blank?
            render 'admin/versions/changeset', changeset: version.changeset, item: version.item
          end
        end
      end
    end
  end

  collection_action :git_commits, method: :get do
    repo = GitConfigRepository.new
    walker = repo.walker_for_version(repo.current_version)

    if params[:order] == 'time_asc'
      walker.sorting(Rugged::SORT_DATE | Rugged::SORT_REVERSE)
    end

    commits = walker.map do |commit|
      # {
      #   :oid => commit.oid,
      #   :message => commit.message,
      #   :author_id => commit.author[:email].to_i,
      #   :author_name => commit.author[:name],
      #   :time => commit.time,
      #   :tree_count => commit.tree.count
      # }
      GitConfigCommit.new(commit)
    end

    @page_title = 'Configuration Changes'
    render 'admin/versions/git_commits', locals: { commits: commits }
  end

  collection_action :show_git_commit, method: :get do
    oid = params[:oid]

    repo = GitConfigRepository.new
    begin
      commit = repo.lookup(oid)
    rescue Rugged::Error => e
      commit = nil
    end

    if commit.nil? || commit.type != :commit
      flash[:error] = 'No such commit exists'
      redirect_back(fallback_location: admin_versions_path)
      return
    end

    @page_title = "Commit #{commit.oid}"
    render 'admin/versions/show_git_commit', locals: { commit: GitConfigCommit.new(commit), repo: repo }
  end

  action_item :edit, only: :index do
    link_to 'Configuration Changes', git_commits_admin_versions_path if can? :git_commits, Version
  end
  action_item :edit, only: :git_commits do
    link_to 'Versions', admin_versions_path({}.merge(params[:audit_trail_view_id].blank? ? {} : { audit_trail_view_id: params[:audit_trail_view_id] }).merge(params[:audit_trail_view_type].blank? ? {} : { audit_trail_view_type: params[:audit_trail_view_type] })) if can? :read, Version
  end
  action_item :edit, only: :show_git_commit do
    link_to 'Back', git_commits_admin_versions_path({}.merge(params[:audit_trail_view_id].blank? ? {} : { audit_trail_view_id: params[:audit_trail_view_id] }).merge(params[:audit_trail_view_type].blank? ? {} : { audit_trail_view_type: params[:audit_trail_view_type] })) if can? :git_commits, Version
  end
end
