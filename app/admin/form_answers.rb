ActiveAdmin.register FormAnswer do
  before_filter { @skip_sidebar = true }

  actions :index, :show, :destroy #TEMP

  controller do
    helper :forms

    load_and_authorize_resource :except => :index
    def scoped_collection
      end_of_association_chain.accessible_by(current_ability)
    end
  end

  index do
    selectable_column
    column :user
    column :session
    column :case
    column :form
    column 'Submission Date', :submitted_at
    column :signatures do |form_answer|
      if(form_answer.answers_signature_is_valid? && form_answer.annotated_images_signature_is_valid?)
        status_tag('Valid', :ok)
      else
        status_tag('Invalid', :error)
      end
    end
    column 'Test Data?', :is_test_data do |form_answer|
      if(form_answer.is_test_data)
        status_tag('Yes', :warning)
      else
        status_tag('No', :ok)
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
      row :form_version
      row :submitted_at
      row :signatures do
        if(form_answer.answers_signature_is_valid? && form_answer.annotated_images_signature_is_valid?)
          status_tag('Valid', :ok)
        else
          status_tag('Invalid', :error)
        end
      end
      row 'Test Data?' do
        if(form_answer.is_test_data)
          status_tag('Yes', :warning)
        else
          status_tag('No', :ok)
        end
      end
      row :answers do
        render "forms/results_table", :caption => '', :cases => [form_answer.case], :skip_header => true
      end
      row :answers_raw do        
        CodeRay.scan(JSON::pretty_generate(form_answer.answers), :json).div(:css => :class).html_safe unless form_answer.answers.nil?
      end
      row :annotated_images_raw do       
        CodeRay.scan(JSON::pretty_generate(form_answer.annotated_images), :json).div(:css => :class).html_safe unless form_answer.annotated_images.nil?
      end
      if(form_answer.case.flag == :reader_testing)
        row 'Reader Testing Judgement' do
          if(FormAnswersController.new.run_form_judgement_function(form_answer) == true)
            status_tag('Passed', :ok)
          else
            status_tag('Failed', :error)
          end
        end
      end
    end
  end
end
