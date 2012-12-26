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
    column :signature do |formanswer|
      if(formanswer.signature_is_valid?)
        status_tag('Valid', :ok)
      else
        status_tag('Invalid', :error)
      end
    end

    default_actions
  end

  show do
    pp form_answer
    pp form_answer.printable_answers
  end
end
