ActiveAdmin.register FormSession do
  menu(parent: 'read', priority: 0)

  permit_params(
    :name,
    :description,
    form_answers_attributes: [:id, :sequence_number]
  )

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
      end
    end

    f.actions
  end
end
