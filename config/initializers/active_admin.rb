# ActiveAdmin extensions like components and mixins

module ActiveAdmin
  module Views; end
end
require_dependency 'active_admin/views/erica_header'
require_dependency 'active_admin/views/erica_site_title'
require_dependency 'active_admin/views/erica_action_items'
require_dependency 'active_admin/views/erica_title_bar'
require_dependency 'active_admin/views/erica_footer'

require 'aa_viewer_cart_mixin'
require 'aa_erica_comment'
require 'aa_erica_keywords'
require 'aa_comment_paper_trail_patch'
require 'aa_views_pages_base'

ActiveAdmin::ResourceDSL.send(:include, ActiveAdmin::ViewerCartMixin::DSL)
ActiveAdmin::ResourceDSL.send(:include, ActiveAdmin::ERICACommentMixin::DSL)
ActiveAdmin::ResourceDSL.send(:include, ActiveAdmin::ERICAKeywordsMixin::DSL)
ActiveAdmin::Comment
ActiveAdmin::Comment.send(:include, ActiveAdminCommentPaperTrailPatch)

ActiveAdmin.setup do |config|
  # == Site Title
  #
  # Set the title that is displayed on the main layout
  # for each of the active admin pages.
  #
  title = Rails.application.config.try(:erica).andand['title']
  config.site_title = title || 'ERICA'

  # Set the link url for the title. For example, to take
  # users to your main site. Defaults to no link.
  #
  # config.site_title_link = "/"

  # Set an optional image to be displayed for the header
  # instead of a string (overrides :site_title)
  #
  # Note: Recommended image height is 21px to properly fit in the header
  #
  # config.site_title_image = "/images/logo.png"
  if Rails.application.config.is_erica_remote && Rails.application.config.erica_remote['logo']
    config.site_title_image = 'client_logos/' + Rails.application.config.erica_remote['logo']
  end

  # == Default Namespace
  #
  # Set the default namespace each administration resource
  # will be added to.
  #
  # eg:
  #   config.default_namespace = :hello_world
  #
  # This will create resources in the HelloWorld module and
  # will namespace routes to /hello_world/*
  #
  # To set no namespace by default, use:
  #   config.default_namespace = false
  #
  # Default:
  # config.default_namespace = :admin
  #
  # You can customize the settings for each namespace by using
  # a namespace block. For example, to change the site title
  # within a namespace:
  #
  #   config.namespace :admin do |admin|
  #     admin.site_title = "Custom Admin Title"
  #   end
  #
  # This will ONLY change the title for the admin section. Other
  # namespaces will continue to use the main "site_title" configuration.

  # == User Authentication
  #
  # Active Admin will automatically call an authentication
  # method in a before filter of all controller actions to
  # ensure that there is a currently logged in admin user.
  #
  # This setting changes the method which Active Admin calls
  # within the application controller.
  config.authentication_method = :authenticate_user!

  # == User Authorization
  #
  # Active Admin will automatically call an authorization
  # method in a before filter of all controller actions to
  # ensure that there is a user with proper rights. You can use
  # CanCanAdapter or make your own. Please refer to documentation.
  config.authorization_adapter = ActiveAdmin::CanCanAdapter

  # In case you prefer Pundit over other solutions you can here pass
  # the name of default policy class. This policy will be used in every
  # case when Pundit is unable to find suitable policy.
  # config.pundit_default_policy = "MyDefaultPunditPolicy"

  # You can customize your CanCan Ability class name here.
  config.cancan_ability_class = 'Ability'

  # You can specify a method to be called on unauthorized access.
  # This is necessary in order to prevent a redirect loop which happens
  # because, by default, user gets redirected to Dashboard. If user
  # doesn't have access to Dashboard, he'll end up in a redirect loop.
  # Method provided here should be defined in application_controller.rb.
  config.on_unauthorized_access = :access_denied

  # == Current User
  #
  # Active Admin will associate actions with the current
  # user performing them.
  #
  # This setting changes the method which Active Admin calls
  # (within the application controller) to return the currently logged in user.
  config.current_user_method = :current_user

  # == Logging Out
  #
  # Active Admin displays a logout link on each screen. These
  # settings configure the location and method used for the link.
  #
  # This setting changes the path where the link points to. If it's
  # a string, the strings is used as the path. If it's a Symbol, we
  # will call the method to return the path.
  #
  # Default:
  config.logout_link_path = :destroy_user_session_path

  # This setting changes the http method used when rendering the
  # link. For example :get, :delete, :put, etc..
  #
  # Default:
  config.logout_link_method = :delete

  # == Root
  #
  # Set the action to call for the root path. You can set different
  # roots for each namespace.
  #
  # Default:
  # config.root_to = 'dashboard#index'

  # == Admin Comments
  #
  # This allows your users to comment on any resource registered with Active Admin.
  #
  # Comments should only available on ERICA remote.
  config.comments = ERICA.remote?

  #
  # You can disable the menu item for the comments index page:
  # config.show_comments_in_menu = false
  #
  # You can change the name under which comments are registered:
  # config.comments_registration_name = 'AdminComment'
  #
  # You can change the order for the comments and you can change the column
  # to be used for ordering
  # config.comments_order = 'created_at ASC'

  # == Batch Actions
  #
  # Enable and disable Batch Actions
  #
  config.batch_actions = true

  # == Controller Filters
  #
  # You can add before, after and around filters to all of your
  # Active Admin resources and pages from here.
  #
  # config.before_filter :do_something_awesome

  # == Localize Date/Time Format
  #
  # Set the localize format to display dates and times.
  # To understand how to localize your app with I18n, read more at
  # https://github.com/svenfuchs/i18n/blob/master/lib%2Fi18n%2Fbackend%2Fbase.rb#L52
  #
  config.localize_format = :long

  # == Setting a Favicon
  #
  # config.favicon = 'favicon.ico'

  # == Meta Tags
  #
  # Add additional meta tags to the head element of active admin pages.
  #
  # Add tags to all pages logged in users see:
  #   config.meta_tags = { author: 'My Company' }

  # By default, sign up/sign in/recover password pages are excluded
  # from showing up in search engine results by adding a robots meta
  # tag. You can reset the hash of meta tags included in logged out
  # pages:
  #   config.meta_tags_for_logged_out_pages = {}

  # == Removing Breadcrumbs
  #
  # Breadcrumbs are enabled by default. You can customize them for individual
  # resources or you can disable them globally from here.
  #
  # config.breadcrumb = false

  # == Register Stylesheets & Javascripts
  #
  # We recommend using the built in Active Admin layout and loading
  # up your own stylesheets / javascripts to customize the look
  # and feel.
  #
  # To load a stylesheet:
  #   config.register_stylesheet 'my_stylesheet.css'

  # You can provide an options hash for more control, which is passed along to stylesheet_link_tag():
  #   config.register_stylesheet 'my_print_stylesheet.css', :media => :print
  #
  # To load a javascript file:
  #   config.register_javascript 'my_javascript.js'

  # == CSV options
  #
  # Set the CSV builder separator
  # config.csv_options = { col_sep: ';' }
  #
  # Force the use of quotes
  # config.csv_options = { force_quotes: true }

  # == Menu System
  #
  # You can add a navigation menu to be used in your application, or configure a provided menu
  #
  # To change the default utility navigation to show a link to your website & a logout btn
  #
  #   config.namespace :admin do |admin|
  #     admin.build_menu :utility_navigation do |menu|
  #       menu.add label: "My Great Website", url: "http://www.mygreatwebsite.com", html_options: { target: :blank }
  #       admin.add_logout_button_to_menu menu
  #     end
  #   end
  #
  # If you wanted to add a static menu item to the default menu provided:
  #
  config.namespace :admin do |admin|
    admin.build_menu :default do |menu|
      menu.add(
        label: 'immediate',
        priority: 0,
        if: proc { !menu['immediate'].children.empty? }
      ) do |immediate|
        immediate.add label: "Tasks", url: "/v1/dashboard"
      end
      menu.add(
        label: 'store',
        priority: 10,
        if: proc { !menu['store'].children.empty? }
      )
      menu.add(
        label: 'meta_store',
        priority: 20,
        if: proc { !menu['meta_store'].children.empty? }
      )
      menu.add(
        label: 'read',
        priority: 30,
        if: proc { !menu['read'].children.empty? }
      )
      menu.add(
        label: 'users',
        priority: 40,
        if: proc { !menu['users'].children.empty? }
      )
      menu.add(
        label: 'notifications',
        priority: 50,
        if: proc { !menu['notifications'].children.empty? }
      )
      menu.add(
        label: 'admin',
        priority: 60,
        if: proc { !menu['admin'].children.empty? }
      )
      menu.add(
        label: 'versions',
        priority: 1000,
        if: proc { !menu['versions'].children.empty? }
      )
    end
    
    admin.build_menu :utility_navigation do |menu|
      admin.add_current_user_to_menu (menu)
      menu.add  id: "logout", priority: 20,
                label: -> { I18n.t "active_admin.logout" },
                html_options: { method: :delete },
                url: -> { render_or_call_method_or_proc_on self, active_admin_namespace.logout_link_path },
                if:  -> { current_active_admin_user? && !session["impersonated_user_id"] }
              
      menu.add  id: "stop_impersonating",
                priority: 20,
                label: -> { "Stop Impersonating" },
                url: -> { "/admin/users/stop_impersonating" },
                if:  -> { current_active_admin_user? && session["impersonated_user_id"] }
               
    end
  end

  # == Download Links
  #
  # You can disable download links on resource listing pages,
  # or customize the formats shown per namespace/globally
  #
  # To disable/customize for the :admin namespace:
  #
  #   config.namespace :admin do |admin|
  #
  #     # Disable the links entirely
  #     admin.download_links = false
  #
  #     # Only show XML & PDF options
  #     admin.download_links = [:xml, :pdf]
  #
  #     # Enable/disable the links based on block
  #     #   (for example, with cancan)
  #     admin.download_links = proc { can?(:view_download_links) }
  #
  #   end

  # == Pagination
  #
  # Pagination is enabled by default for all resources.
  # You can control the default per page count for all resources here.
  #
  # config.default_per_page = 30
  #
  # You can control the max per page count too.
  #
  # config.max_per_page = 10_000

  # == Filters
  #
  # By default the index screen includes a "Filters" sidebar on the right
  # hand side with a filter for each attribute of the registered model.
  # You can enable or disable them for all resources here.
  #
  # config.filters = true

  # == Extend View
  #
  # Render custom ERICA footer and title.
  #
  config.view_factory.register header: ActiveAdmin::Views::EricaHeader
  config.view_factory.register site_title: ActiveAdmin::Views::EricaSiteTitle
  config.view_factory.register action_items: ActiveAdmin::Views::EricaActionItems
  config.view_factory.register title_bar: ActiveAdmin::Views::EricaTitleBar
  config.view_factory.register footer: ActiveAdmin::Views::EricaFooter
end

ActiveAdmin::BaseController.class_eval do
  helper ApplicationHelper

  def authorize_one!(actions, subject)
    unless actions.any? { |a| can?(a, subject) }
      raise CanCan::AccessDenied.new(current_user, actions, subject)
    end
  end

  def authorize_combination!(*combinations)
    unless combinations.any? { |a, s| can?(a, s) }
      raise CanCan::AccessDenied.new(current_user, combinations)
    end
  end
end

# Taken from https://github.com/DocSpring/inherited_resources/commit/20d2eae2ee7b56c8a8494a6fb5fbc5afbb0bec7b#diff-86482bddc1bf1df5782fea3d119772887ef90a779693ccd114cc518cb700be22
# Fixes for Rails 5.2
# TODO: Remove after updating `inherited_resources` to 1.13
module InheritedResources
  # = URLHelpers
  #
  # When you use InheritedResources it creates some UrlHelpers for you.
  # And they handle everything for you.
  #
  #  # /posts/1/comments
  #  resource_url          # => /posts/1/comments/#{@comment.to_param}
  #  resource_url(comment) # => /posts/1/comments/#{comment.to_param}
  #  new_resource_url      # => /posts/1/comments/new
  #  edit_resource_url     # => /posts/1/comments/#{@comment.to_param}/edit
  #  collection_url        # => /posts/1/comments
  #  parent_url            # => /posts/1
  #
  #  # /projects/1/tasks
  #  resource_url          # => /projects/1/tasks/#{@task.to_param}
  #  resource_url(task)    # => /projects/1/tasks/#{task.to_param}
  #  new_resource_url      # => /projects/1/tasks/new
  #  edit_resource_url     # => /projects/1/tasks/#{@task.to_param}/edit
  #  collection_url        # => /projects/1/tasks
  #  parent_url            # => /projects/1
  #
  #  # /users
  #  resource_url          # => /users/#{@user.to_param}
  #  resource_url(user)    # => /users/#{user.to_param}
  #  new_resource_url      # => /users/new
  #  edit_resource_url     # => /users/#{@user.to_param}/edit
  #  collection_url        # => /users
  #  parent_url            # => /
  #
  # The nice thing is that those urls are not guessed during runtime. They are
  # all created when you inherit.
  #
  module UrlHelpers
    protected

      # This method hard code url helpers in the class.
      #
      # We are doing this because is cheaper than guessing them when our action
      # is being processed (and even more cheaper when we are using nested
      # resources).
      #
      # When we are using polymorphic associations, those helpers rely on
      # polymorphic_url Rails helper.
      #
      def create_resources_url_helpers!
        resource_segments, resource_ivars = [], []
        resource_config = self.resources_configuration[:self]

        singleton   = resource_config[:singleton]
        uncountable = !singleton && resource_config[:route_collection_name] == resource_config[:route_instance_name]
        polymorphic = self.parents_symbols.include?(:polymorphic)

        # Add route_prefix if any.
        unless resource_config[:route_prefix].blank?
          if polymorphic
            resource_ivars << resource_config[:route_prefix].to_sym
          else
            resource_segments << resource_config[:route_prefix]
          end
        end

        # Deal with belongs_to associations and polymorphic associations.
        # Remember that we don't have to build the segments in polymorphic cases,
        # because the url will be polymorphic_url.
        #
        self.parents_symbols.each do |symbol|
          if symbol == :polymorphic
            resource_ivars << :parent
          else
            config = self.resources_configuration[symbol]
            if config[:singleton] && polymorphic
              resource_ivars << config[:instance_name]
            else
              resource_segments << config[:route_name]
            end
            if !config[:singleton]
              resource_ivars    << :"@#{config[:instance_name]}"
            end
          end
        end

        collection_ivars    = resource_ivars.dup
        collection_segments = resource_segments.dup

        # Generate parent url before we add resource instances.
        unless parents_symbols.empty?
          generate_url_and_path_helpers nil,   :parent, resource_segments, resource_ivars
          generate_url_and_path_helpers :edit, :parent, resource_segments, resource_ivars
        end

        # In singleton cases, we do not send the current element instance variable
        # because the id is not in the URL. For example, we should call:
        #
        #   project_manager_url(@project)
        #
        # Instead of:
        #
        #   project_manager_url(@project, @manager)
        #
        # Another exception in singleton cases is that collection url does not
        # exist. In such cases, we create the parent collection url. So in the
        # manager case above, the collection url will be:
        #
        #    project_url(@project)
        #
        # If the singleton does not have a parent, it will default to root_url.
        #
        collection_segments << resource_config[:route_collection_name] unless singleton
        resource_segments   << resource_config[:route_instance_name]
        resource_ivars      << :"@#{resource_config[:instance_name]}" unless singleton

        # Finally, polymorphic cases we have to give hints to the polymorphic url
        # builder. This works by attaching new ivars as symbols or records.
        #
        if polymorphic && singleton
          resource_ivars << resource_config[:instance_name]
          new_ivars       = resource_ivars
        end

        # If route is uncountable then add "_index" suffix to collection index route name
        if uncountable
          collection_segments << :"#{collection_segments.pop}_index"
        end

        generate_url_and_path_helpers nil,   :collection, collection_segments, collection_ivars
        generate_url_and_path_helpers :new,  :resource,   resource_segments,   new_ivars || collection_ivars
        generate_url_and_path_helpers nil,   :resource,   resource_segments,   resource_ivars
        generate_url_and_path_helpers :edit, :resource,   resource_segments,   resource_ivars

        if resource_config[:custom_actions]
          [*resource_config[:custom_actions][:resource]].each do | method |
            generate_url_and_path_helpers method, :resource, resource_segments, resource_ivars
          end
          [*resource_config[:custom_actions][:collection]].each do | method |
            generate_url_and_path_helpers method, :resources, collection_segments, collection_ivars
          end
        end
      end

      def handle_shallow_resource(prefix, name, segments, ivars) #:nodoc:
        return segments, ivars unless self.resources_configuration[:self][:shallow]
        case name
        when :collection, :resources
          segments = segments[-2..-1]
          ivars = [ivars.last]
        when :resource
          if prefix == :new
            segments = segments[-2..-1]
            ivars = [ivars.last]
          else
            segments = [segments.last]
            ivars = [ivars.last]
          end
        when :parent
          segments = [segments.last]
          ivars = [ivars.last]
        end

        segments ||= []

        unless self.resources_configuration[:self][:route_prefix].blank?
          segments.unshift self.resources_configuration[:self][:route_prefix]
        end

        return segments, ivars
      end

      def generate_url_and_path_helpers(prefix, name, resource_segments, resource_ivars) #:nodoc:
        resource_segments, resource_ivars = handle_shallow_resource(prefix, name, resource_segments, resource_ivars)

        ivars       = resource_ivars.dup
        singleton   = self.resources_configuration[:self][:singleton]
        polymorphic = self.parents_symbols.include?(:polymorphic)

        # In collection in polymorphic cases, allow an argument to be given as a
        # replacemente for the parent.
        #
        parent_index = ivars.index(:parent) if polymorphic

        segments = if polymorphic
          :polymorphic
        elsif resource_segments.empty?
          'root'
        else
          resource_segments.join('_')
        end

        define_params_helper(prefix, name, singleton, polymorphic, parent_index, ivars)
        define_helper_method(prefix, name, :path, segments)
        define_helper_method(prefix, name, :url, segments)
      end

      def define_params_helper(prefix, name, singleton, polymorphic, parent_index, ivars)
        params_method_name = ['', prefix, name, :params].compact.join('_')

        undef_method params_method_name if method_defined? params_method_name

        define_method params_method_name do |*given_args|
          given_args = given_args.collect { |arg| arg.respond_to?(:permitted?) ? arg.to_h : arg }
          given_options = given_args.extract_options!

          args = ivars.map do |ivar|
            ivar.is_a?(Symbol) && ivar.to_s.start_with?('@') ? instance_variable_get(ivar) : ivar
          end
          args[parent_index] = parent if parent_index

          if !(singleton && name != :parent) && args.present? && name != :collection && prefix != :new
            resource = args.pop
            args.push(given_args.first || resource)
          end

          if polymorphic
            if name == :collection
              args[parent_index] = given_args.present? ? given_args.first : parent
            end
            if (name == :collection || name == :resource && prefix == :new) && !singleton
              args << (@_resource_class_new ||= resource_class.new)
            end
            args.compact! if self.resources_configuration[:polymorphic][:optional]
            args = [args]
          end
          args << given_options
        end
        protected params_method_name
      end

      def define_helper_method(prefix, name, suffix, segments)
        method_name = [prefix, name, suffix].compact.join('_')
        params_method_name = ['', prefix, name, :params].compact.join('_')
        segments_method = [prefix, segments, suffix].compact.join('_')

        undef_method method_name if method_defined? method_name

        define_method method_name do |*given_args|
          given_args = send params_method_name, *given_args
          send segments_method, *given_args
        end
        protected method_name
      end

  end
end
