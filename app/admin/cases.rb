ActiveAdmin.register Case do

  actions :index, :show, :destroy

  index do
    selectable_column
    column :session
    column :position
    column :patient
    column :images
    column :case_type
    column :form_answer do |c|
      if(c.form_answer.nil?)
        status_tag('None', :error)
      else
        status_tag('available', :ok, :label => link_to('Available', admin_form_answer_path(c.form_answer)).html_safe)
        #link_to('Available', admin_form_answer_path(c.form_answer))
      end
    end
    
    default_actions
  end
end
