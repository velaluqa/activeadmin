module ActiveAdmin
  class Resource
    def add_default_show_action_item
      add_action_item :destroy, only: :show do
        localizer = ActiveAdmin::Localizers.resource(active_admin_config)

        if controller.action_methods.include?("destroy") && authorized?(ActiveAdmin::Auth::DESTROY, resource)
          link_to(
            localizer.t(:delete_model),
            resource_path(resource),
            method: :delete,
            data: {
              override_prompt_param: "versions_comment",
              override_prompt_text: localizer.t(:delete_confirmation) + "\n" + "Please provide a reason for performing your action:"
            },
            class: 'member_link delete_link'
          )
        end
      end
    end
  end
end
