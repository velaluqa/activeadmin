module ActiveAdmin
  module Views
    module Pages
      class Base < Arbre::HTML::Document
        alias original_build_active_admin_head build_active_admin_head
        def build_active_admin_head
          original_build_active_admin_head

          within @head do
            render partial: 'layouts/script_current_user'
            render partial: 'layouts/script_studies'
          end
        end
      end
    end
  end
end
