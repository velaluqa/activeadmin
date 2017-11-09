require 'aa_customizable_default_actions'
require 'aa_domino'
require 'aa_erica_keywords'

ActiveAdmin.register Center do
  menu(parent: 'store', priority: 10)

  actions :index, :show if ERICA.remote?

  config.sort_order = 'code_asc'

  controller do
    def max_csv_records
      1_000_000
    end

    def scoped_collection
      if session[:selected_study_id].present?
        end_of_association_chain.where(study_id: session[:selected_study_id])
      else
        end_of_association_chain
      end
    end

    before_filter :authorize_erica_remote, only: :index, if: -> { ERICA.remote? }
    def authorize_erica_remote
      return if params[:format].blank?
      authorize! :download_status_files, Center
    end
  end

  index do
    selectable_column
    column :study, sortable: :study_id
    column :code
    column :name
    keywords_column(:tags, 'Keywords') if ERICA.remote?

    customizable_default_actions(current_ability) do |resource|
      resource.patients.empty? ? [] : [:destroy]
    end
  end

  show do |center|
    attributes_table do
      row :study
      row :code
      row :name
      domino_link_row(center)
      row :image_storage_path
      keywords_row(center, :tags, 'Keywords') if ERICA.remote?
    end
    active_admin_comments if can?(:comment, center)
  end

  form do |f|
    f.object.study_id = params[:study_id] if params.key?(:study_id)
    f.inputs 'Details' do
      unless f.object.persisted?
        studies = Study.accessible_by(current_ability).order(:name, :id)
        if session[:selected_study_id].present?
          studies = studies.where(id: session[:selected_study_id])
        end
        f.input(
          :study,
          collection: studies,
          input_html: {
            class: 'initialize-select2',
            'data-placeholder' => 'Select a Study'
          }
        )
      end
      f.input(:name)
      f.input(
        :code,
        hint: f.object.persisted? && t('admin.centers.form.code.hint')
      )
    end

    f.actions
  end

  # filters
  filter :study, collection: lambda {
    if session[:selected_study_id].present?
      Study
        .accessible_by(current_ability)
        .where(id: session[:selected_study_id])
    else
      Study.accessible_by(current_ability)
    end
  }
  filter :name
  filter :code
  keywords_filter(:tags, 'Keywords') if ERICA.remote?

  viewer_cartable(:center)
  erica_keywordable(:tags, 'Keywords') if ERICA.remote?

  action_item :audit_trail, only: :show, if: -> { can?(:read, Version) } do
    url = admin_versions_path(
      audit_trail_view_type: 'center',
      audit_trail_view_id: resource.id
    )
    link_to('Audit Trail', url)
  end
end
