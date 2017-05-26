module ActiveAdmin
  module Views
    class IndexAsTable
      def customizable_default_actions(ability = nil, &block)
        column '' do |resource|
          # most of this is copied from activeadmin/lib/active_admin/views/index_as_table.rb#default_actions
          # since we can't customize its behaviour
          except = if block
                     yield(resource)
                   else
                     []
                   end

          if ability
            except << :show unless ability.can? :read, resource
            except << :edit unless ability.can? :edit, resource
            except << :destroy unless ability.can? :destroy, resource
          end

          links = ''.html_safe
          if controller.action_methods.include?('show') && !except.include?(:show)
            links << link_to(I18n.t('active_admin.view'), resource_path(resource), class: 'member_link view_link')
          end
          if controller.action_methods.include?('edit') && !except.include?(:edit)
            links << link_to(I18n.t('active_admin.edit'), edit_resource_path(resource), class: 'member_link edit_link')
          end
          if controller.action_methods.include?('destroy') && !except.include?(:destroy)
            links << link_to(I18n.t('active_admin.delete'), resource_path(resource), method: :delete, data: { confirm: I18n.t('active_admin.delete_confirmation') }, class: 'member_link delete_link')
          end
          links
        end
      end
    end
  end
end
