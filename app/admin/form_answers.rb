ActiveAdmin.register FormAnswer do
  before_filter { @skip_sidebar = true }

  index do
    selectable_column
    column :user
    column :session
    column :form
    column :patient
    column :images
    column 'Submission Date', :submitted_at
    column :signature do |form_answer|
      if(form_answer.signature_is_valid?)
        status_tag('Valid', :ok)
      else
        status_tag('Invalid', :error)
      end
    end

    default_actions
  end

  show do |form_answer|
    attributes_table do
      row :user
      row :session
      row :form
      row :patient
      row :images
      row :submitted_at
      row :signature do
        if(form_answer.signature_is_valid?)
          status_tag('Valid', :ok)
        else
          status_tag('Invalid', :error)
        end
      end
      row :answers do
        render "forms/results", :fields => form_answer.printable_answers, :display_type => 'review'
      end
    end
  end
end
