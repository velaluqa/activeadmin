require 'git_config_repository'

ActiveAdmin.register Version do
  menu :label => 'Audit Trail', :priority => 99, :if => proc{ can?(:manage, Version) }

  actions :index, :show

  filter :created_at
  filter :item_type, :as => :select, :collection => ['Case', 'Form', 'Patient', 'Role', 'Session', 'Study' , 'User']
  filter :whodunnit, :label => 'User', :as => :select, :collection => proc { User.all }
  filter :event, :as => :check_boxes, :collection => ['create', 'update', 'destroy']

  controller do
    def scoped_collection
      return end_of_association_chain if(params[:audit_trail_view_type].nil? or params[:audit_trail_view_id].nil?)

      case params[:audit_trail_view_type]
      when 'case'
        end_of_association_chain.where('item_type LIKE \'Case\' and item_id = ?', params[:audit_trail_view_id].to_i)
      when 'patient'
        end_of_association_chain.where('(item_type LIKE \'Patient\' and item_id = :patient_id) or (item_type LIKE \'Case\' and item_id IN (SELECT id FROM cases WHERE cases.patient_id = :patient_id))', {:patient_id => params[:audit_trail_view_id].to_i})
      when 'form'
        end_of_association_chain.where('item_type LIKE \'Form\' and item_id = ?', params[:audit_trail_view_id].to_i)
      when 'role'
        end_of_association_chain.where('item_type LIKE \'Role\' and item_id = ?', params[:audit_trail_view_id].to_i)
      when 'user'
        end_of_association_chain.where('(item_type LIKE \'User\' and item_id = :user_id) or (item_type LIKE \'Role\' and item_id IN (SELECT id FROM roles WHERE roles.user_id = :user_id))',
                                       {:user_id => params[:audit_trail_view_id].to_i})
      when 'session'
        end_of_association_chain.where('(item_type LIKE \'Session\' and item_id = :session_id) or (item_type LIKE \'Case\' and item_id IN (SELECT id FROM cases WHERE cases.session_id = :session_id)) or (item_type LIKE \'Patient\' and item_id IN (SELECT id FROM patients WHERE patients.session_id = :session_id)) or (item_type LIKE \'Form\' and item_id IN (SELECT id FROM forms WHERE forms.session_id = :session_id))',
                                       {:session_id => params[:audit_trail_view_id].to_i})
      when 'study'
        end_of_association_chain.where('(item_type LIKE \'Study\' and item_id = :study_id) or (item_type LIKE \'Session\' and item_id IN (SELECT id FROM sessions WHERE sessions.study_id = :study_id)) or (item_type LIKE \'Case\' and item_id IN (SELECT id FROM cases WHERE cases.session_id IN (SELECT id FROM sessions WHERE sessions.study_id = :study_id))) or (item_type LIKE \'Patient\' and item_id IN (SELECT id FROM patients WHERE patients.session_id IN (SELECT id FROM sessions WHERE sessions.study_id = :study_id))) or (item_type LIKE \'Form\' and item_id IN (SELECT id FROM forms WHERE forms.session_id IN (SELECT id FROM sessions WHERE sessions.study_id = :study_id)))',
                                       {:study_id => params[:audit_trail_view_id].to_i})
      else
        end_of_association_chain
      end.accessible_by(current_ability)
    end

    def self.classify_event(version)
      return version.event if version.changeset.nil?
      pp version.changeset
      c = version.changeset

      case version.item_type
      when 'User'
        if(c.include?('sign_in_count') and
           c['sign_in_count'][1] == c['sign_in_count'][0]+1
           )
          return :sign_in
        elsif(c.include?('encrypted_password') and
              c.include?('password_changed_at'))
          return :password_change
        elsif(c.include?('failed_attempts'))
          if(c['failed_attempts'][1] > c['failed_attempts'][0])
            if(c.include?('locked_at') and not c['locked_at'][1].blank?)
               return :user_locked
            else
              return :failed_login
            end
          elsif(c['failed_attempts'][1] == 0 and c.include?('locked_at') and c['locked_at'][1].blank?)
            return :user_unlocked
          end
        elsif(c.include?('private_key') and c.include?('public_key'))
          return :key_change
        end
      when 'Case'
        if(c.include?('state'))
          case c['state']
          when [Case::state_sym_to_int(:unread), :in_progress], [Case::state_sym_to_int(:reopened), :reopened_in_progress]
            return :case_reservation
          when [Case::state_sym_to_int(:in_progress), :unread], [Case::state_sym_to_int(:reopened_in_progress), :reopened]
            return :case_cancelation
          when [Case::state_sym_to_int(:in_progress), :read], [Case::state_sym_to_int(:reopened_in_progress), :read]
            return :case_completion
          when [Case::state_sym_to_int(:read), :reopened]
            return :case_reopened
          end
        end
      end

      return version.event
    end
    def self.event_title_and_severity(event)
      return case event
             when 'create' then ['Create', :ok]
             when 'update' then ['Update', :warning]
             when 'destroy' then ['Destroy', :error]
             when :sign_in then ['Sign-In', :ok]
             when :password_change then ['Password Change', :warning]
             when :failed_login then ['Failed Sign-In attempt', :warning]
             when :user_locked then ['User locked', :error]
             when :user_unlocked then ['User unlocked', :warning]
             when :key_change then ['Keypair Change', :warning]
             when :case_reservation then ['Case Reservation', :warning]
             when :case_cancelation then ['Case Cancelation', :error]
             when :case_completion then ['Case Completion', :ok]
             when :case_reopened then ['Case Reopened', :error]
             end
    end

    def audit_trail_resource
      return nil if(params[:audit_trail_view_type].blank? or params[:audit_trail_view_id].blank?)

      result = case params[:audit_trail_view_type]
               when 'case' then Case.where(:id => params[:audit_trail_view_id].to_i).first
               when 'patient' then Patient.where(:id => params[:audit_trail_view_id].to_i).first
               when 'form' then Form.where(:id => params[:audit_trail_view_id].to_i).first
               when 'role' then Role.where(:id => params[:audit_trail_view_id].to_i).first
               when 'user' then User.where(:id => params[:audit_trail_view_id].to_i).first
               when 'session' then Session.where(:id => params[:audit_trail_view_id].to_i).first
               when 'study' then Study.where(:id => params[:audit_trail_view_id].to_i).first
               when 'form_answer' then FormAnswer.where(:id => params[:audit_trail_view_id]).first
               else nil
               end

      return result
    end
  end

  action_item :only => :index do
    resource = controller.audit_trail_resource
    status_tag(params[:audit_trail_view_type] + ': ' + (resource.respond_to?(:name) ? resource.name : '<'+resource.id+'>'), :error, :class => 'audit_trail_indicator') unless resource.nil?
  end

  index do
    selectable_column
    column 'Timestamp', :created_at
    column :item_type
    column :item do |version|
      auto_link(version.item)
    end
    column :event do |version|
      event = Admin::VersionsController.classify_event(version)
      event_title, event_severity = Admin::VersionsController.event_title_and_severity(event)
      status_tag(event_title, event_severity)
    end
    column :user, :sortable => :whodunnit do |version|
      if version.whodunnit.blank?
        'System'
      else
        auto_link(User.find_by_id(version.whodunnit.to_i))
      end
    end

    default_actions
  end

  show do |version|
    attributes_table do
      row :created_at
      row :item_type
      row :item do
        auto_link(version.item)
      end
      row :event do
        event = Admin::VersionsController.classify_event(version)
        event_title, event_severity = Admin::VersionsController.event_title_and_severity(event)
        status_tag(event_title, event_severity)
      end
      row :user do
        if version.whodunnit.blank?
          'System'
        else
          auto_link(User.find_by_id(version.whodunnit.to_i))
        end
      end
      row :changes do
        unless(version.changeset.blank?)
          render 'admin/versions/changeset', :changeset => version.changeset, :item => version.item
        end
      end
    end
  end

  collection_action :git_commits, :method => :get do
    repo = GitConfigRepository.new
    walker = repo.walker_for_version(repo.current_version)

    if(params[:order] == 'time_asc')
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
    render 'admin/versions/git_commits', :locals => {:commits => commits}
  end

  collection_action :show_git_commit, :method => :get do
    oid = params[:oid]
    
    repo = GitConfigRepository.new
    begin
      commit = repo.lookup(oid)
    rescue Rugged::Error => e
      commit = nil
    end

    if(commit.nil? or commit.type != :commit)
      flash[:error] = 'No such commit exists'
      redirect_to :back
      return
    end

    @page_title = "Commit #{commit.oid}"
    render 'admin/versions/show_git_commit', :locals => {:commit => GitConfigCommit.new(commit), :repo => repo}
  end

  action_item :only => :index do
    link_to 'Configuration Changes', git_commits_admin_versions_path
  end
  action_item :only => :git_commits do
    link_to 'Versions', admin_versions_path({}.merge(params[:audit_trail_view_id].blank? ? {} : {:audit_trail_view_id => params[:audit_trail_view_id]}).merge(params[:audit_trail_view_type].blank? ? {} : {:audit_trail_view_type => params[:audit_trail_view_type]}))
  end
  action_item :only => :show_git_commit do
    link_to 'Back', git_commits_admin_versions_path({}.merge(params[:audit_trail_view_id].blank? ? {} : {:audit_trail_view_id => params[:audit_trail_view_id]}).merge(params[:audit_trail_view_type].blank? ? {} : {:audit_trail_view_type => params[:audit_trail_view_type]}))
  end
  action_item :only => [:index, :git_commits] do
    link_to 'MongoDB', admin_mongoid_history_trackers_path({}.merge(params[:audit_trail_view_id].blank? ? {} : {:audit_trail_view_id => params[:audit_trail_view_id]}).merge(params[:audit_trail_view_type].blank? ? {} : {:audit_trail_view_type => params[:audit_trail_view_type]}))
  end
end
