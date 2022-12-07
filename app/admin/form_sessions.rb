ActiveAdmin.register FormSession do
  menu(parent: 'read', priority: 0)
    
  permit_params(
    :name,
    :description,
    form_answers_attributes: [:id, :sequence_number]
  )

  controller do
    def destroy
      form_session = FormSession.find(params[:id])
      if form_session.form_answers.exists?
        flash[:error] = 'Cannot delete session with associated form data.'
        redirect_back(fallback_location: admin_form_sessions_path)
        return
      end

      destroy!
    end
  end

  index do
    selectable_column
    column :name
    customizable_default_actions(current_ability)
  end

  show do |session|
    attributes_table do
      row :name
      row :description
    end

    panel "Tasks & Form Data" do
      table_for FormAnswerDecorator.decorate_collection(session.form_answers.order(sequence_number: :asc)) do
        column "#", :sequence_number
        column "Form", :form_definition
        column :resources
        column :status
        column "User", :user, sortable: "users.name"
        column :published_at
        column :submitted_at
      end
    end
  end

  form do |f|
    f.inputs 'Details' do
      f.input :name
      f.input :description
    end

    f.inputs 'Tasks' do

      f.has_many :form_answers, new_record: false, sortable: :sequence_number, sortable_start: 1 do |fa|
        fa.input :form_definition_label, as: :readonly, input_html: { disabled: true }
        fa.input :resource_labels, as: :readonly, input_html: { disabled: true }
        fa.input :status, as: :readonly, input_html: { disabled: true }
        fa.input :user_label, as: :readonly, input_html: { disabled: true }
        fa.input :published_at_label, as: :readonly, input_html: { disabled: true }
        fa.input :submitted_at_label, as: :readonly, input_html: { disabled: true }
      end
    end

    f.actions
  end

  action_item :edit, only: :show do
    link_to "Publish all Form Answers", publish_admin_form_session_path(resource) if resource.form_answers.draft.exists?
  end

  member_action :publish, method: :get do
    form_session = FormSession.find(params[:id])
    form_session.form_answers.draft.map(&:publish!)
    redirect_back(fallback_location: admin_form_session_path(form_session))
  end
end
