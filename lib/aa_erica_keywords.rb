module ActiveAdmin
  module Views
    class IndexAsTable
      def tags_column(context, label)

        label ||= context.to_s.humanize

        column label, context do |resource|
          can_edit = can? :update_tags, resource

          if resource.tags_on(context).empty?
            link_to('Add ' + label, url_for(action: :edit_erica_tags_form, id: resource.id, return_url: request.fullpath)) if can_edit
          else
            tag_list = resource.tag_list_on(context).map { |t| link_to(t, action: :index, q: { context.to_s.singularize + '_taggings_tag_name_eq' => t }) }.join(', ')
            tag_list += link_to(' <i class="fa fa-pencil"></i>'.html_safe, url_for(action: :edit_erica_tags_form, id: resource.id, return_url: request.fullpath), class: 'member_link') if can_edit

            tag_list.html_safe
          end
        end
      end
    end

    class AttributesTable
      def tags_row(resource, context, label, can_edit = nil)
        label ||= context.to_s.humanize

        can_edit = can? :update_tags, resource if can_edit.nil?

        row label do
          if resource.tags_on(context).empty?
            link_to('Add ' + label, url_for(action: :edit_erica_tags_form, id: resource.id, return_url: request.fullpath)) if can_edit
          else
            tag_list = resource.tag_list_on(context).map { |t| link_to(t, action: :index, q: { context.to_s.singularize + '_taggings_tag_name_eq' => t }) }.join(', ')
            tag_list += link_to(' <i class="fa fa-pencil"></i>'.html_safe, url_for(action: :edit_erica_tags_form, id: resource.id, return_url: request.fullpath), class: 'member_link') if can_edit

            tag_list.html_safe
          end
        end
      end
    end
  end

  module Filters
    module DSL
      def tags_filter(context, label)
        label ||= context.to_s.humanize

        field_name = context.to_s.singularize + '_taggings_tag_name'
        filter field_name.to_sym, label: label, as: :select, if: proc { can?(:read_tags, resource_class) }, collection: -> { resource_class.tag_counts_on(context).map { |tag| ["#{tag.name} (#{tag.taggings_count})", tag.name] } }, input_html: {
          class: 'tagfilter no-auto-select2'
        }
      rescue StandardError => e
        # TODO: Clean up this mess! We actually have to check, whether
        # we are in a migration or not. Or maybe if the current
        # migration is later than the one that introduced the tags
        # package.
        if e.message =~ /relation "tags" does not exist/
          puts 'ActsAsTaggable not yet migrated. Not loading keyword_filters.'
        else
          raise e
        end
      end
    end
  end

  module ERICAKeywordsMixin
    module DSL
      def erica_taggable(context, label)
        label ||= context.to_s.humanize

        member_action :autocomplete_tags do
          @resource = resource_class.find(params[:id])
          authorize! :update_tags, @resource

          term = params[:q]
          context = params[:context]

          tags = resource_class
                   .tags_on(context)
                   .where('name LIKE ?', "#{term}%")
                   .order(:name)
                   .pluck(:name)

          respond_to do |format|
            format.json { render json: tags }
          end
        end

        member_action :edit_erica_tags, method: :post do
          @resource = resource_class.find(params[:id])

          authorize! :update_tags, @resource

          if can?(:create_tags, @resource)
            new_keywords = params[:tags]
          else
            available_keywords = resource_class.tag_counts_on(context).map(&:name)
            new_keywords = params[:tags] & available_keywords
          end

          @resource.set_tag_list_on(context, new_keywords)
          @resource.save

          if params[:return_url].blank?
            redirect_to action: :index, notice: label + ' changed.'
          else
            redirect_to params[:return_url], notice: label + ' changed.'
          end
        end

        member_action :edit_erica_tags_form, method: :get do
          @resource = resource_class.find(params[:id])
          authorize! :update_tags, @resource

          @return_url = params[:return_url]
          @page_title = 'Edit ' + label
          @label = label
          @context = context

          render 'admin/shared/edit_erica_keywords_form'
        end
      end
    end
  end
end
