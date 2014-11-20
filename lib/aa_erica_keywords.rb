module ActiveAdmin
  module Views

    class IndexAsTable
      def keywords_column(context, label)
        label ||= context.to_s.humanize

        column label do |resource|
          can_edit = can? :edit_keywords, resource

          if(resource.tags_on(context).empty?)
            link_to('Add '+label, url_for(:action => :edit_erica_keywords_form, :id => resource.id, :return_url => request.fullpath)) if can_edit
          else
            tag_list = resource.tag_list_on(context).join(', ')
            tag_list += link_to(icon(:pen), url_for(:action => :edit_erica_keywords_form, :id => resource.id, :return_url => request.fullpath), :class => 'member_link') if can_edit

            tag_list.html_safe
          end
        end
      end
    end

    class AttributesTable
      def keywords_row(resource, context, label, can_edit = nil)
        label ||= context.to_s.humanize

        can_edit ||= can? :edit_keywords, resource

        row label do
          if(resource.tags_on(context).empty?)
            link_to('Add '+label, url_for(:action => :edit_erica_keywords_form, :id => resource.id, :return_url => request.fullpath)) if can_edit
          else
            tag_list = resource.tag_list_on(context).join(', ')
            tag_list += link_to(icon(:pen), url_for(:action => :edit_erica_keywords_form, :id => resource.id, :return_url => request.fullpath), :class => 'member_link') if can_edit

            tag_list.html_safe
          end
        end
      end
    end

  end

  module ERICAKeywordsMixin
    module DSL
      def erica_keywordable(context, label)
        label ||= context.to_s.humanize

        member_action :edit_erica_keywords, :method => :post do
          @resource = resource_class.find(params[:id])
          authorize! :edit_keywords, @resource

          # verify keywords are valid for this study
          unless(@resource.kind_of?(Study))
            new_keywords = ActsAsTaggableOn::DefaultParser.new(params[:keywords]).parse
            new_keywords = new_keywords & @resource.study.tag_list_on(context)
          else
            new_keywords = params[:keywords]
          end

          @resource.set_tag_list_on(context, new_keywords)
          @resource.save

          if(params[:return_url].blank?)
            redirect_to :action => :index, :notice => label+' changed.'
          else
            redirect_to params[:return_url], :notice => label+' changed.'
          end
        end
        member_action :edit_erica_keywords_form, :method => :get do
          @resource = resource_class.find(params[:id])
          authorize! :edit_keywords, @resource

          @return_url = params[:return_url]
          @page_title = 'Edit '+label
          @label = label
          @context = context

          render 'admin/shared/edit_erica_keywords_form'
        end
      end
    end
  end

end
