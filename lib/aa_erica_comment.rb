module ActiveAdmin
  module Views

    class IndexAsTable
      def comment_column(field, label)
        label ||= resource_class.human_attribute_name(field)

        column label do |resource|
          if(resource[field].blank?)
            link_to('Add '+label, url_for(:action => :edit_erica_comment_form, :id => resource.id, :return_url => request.fullpath))
          else
            (resource[field] + link_to(' <i class="fa fa-pencil"></i>'.html_safe, url_for(:action => :edit_erica_comment_form, :id => resource.id, :return_url => request.fullpath), :class => 'member_link')).html_safe
          end
        end
      end
    end

    class AttributesTable
      def comment_row(resource, field, label)
        label ||= resource_class.human_attribute_name(field)

        row label do
          if(resource[field].blank?)
            link_to('Add '+label, url_for(:action => :edit_erica_comment_form, :return_url => request.fullpath))
          else
            (resource[field] + link_to(' <i class="fa fa-pencil"></i>'.html_safe, url_for(:action => :edit_erica_comment_form, :return_url => request.fullpath), :class => 'member_link')).html_safe
          end
        end
      end
    end

  end

  module ERICACommentMixin
    module DSL
      def erica_commentable(field, label)
        label ||= resource_class.human_attribute_name(field)

        member_action :edit_erica_comment, :method => :post do
          @resource = resource_class.find(params[:id])
          authorize! :manage, @resource

          @resource[field] = params[resource_class.name.underscore][field.to_sym]
          @resource.save

          if(params[:return_url].blank?)
            redirect_to :action => :index, :notice => label+' changed.'
          else
            redirect_to params[:return_url], :notice => label+' changed.'
          end
        end
        member_action :edit_erica_comment_form, :method => :get do
          @resource = resource_class.find(params[:id])
          authorize! :manage, @resource

          @return_url = params[:return_url]
          @page_title = 'Edit '+label
          @label = label
          @field = field.to_sym

          render 'admin/shared/edit_erica_comment_form'
        end
      end
    end
  end

end
