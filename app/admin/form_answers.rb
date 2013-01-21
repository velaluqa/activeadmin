ActiveAdmin.register FormAnswer do
  before_filter { @skip_sidebar = true }

  actions :index, :show, :destroy #TEMP

  controller do
    helper :forms
  end

  index do
    selectable_column
    column :user
    column :session
    column :case
    column :form
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
      row :case
      row :form
      row :submitted_at
      row :signature do
        if(form_answer.signature_is_valid?)
          status_tag('Valid', :ok)
        else
          status_tag('Invalid', :error)
        end
      end
      row :answers do
        render "forms/results_table", :caption => '', :cases => [form_answer.case], :skip_header => true
        #render "forms/results", :fields => form_answer.printable_answers, :display_type => 'review'
      end
      row :answers_raw do        
        CodeRay.scan(JSON::pretty_generate(form_answer.answers), :json).div(:css => :class).html_safe
      end
    end
  end
end
