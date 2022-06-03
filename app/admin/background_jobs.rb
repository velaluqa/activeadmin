ActiveAdmin.register BackgroundJob do
  menu(
    parent: 'admin',
    priority: 10
  )

  before_action { @skip_sidebar = true }

  config.filters = false
  config.comments = false
  actions :index, :show, :destroy

  scope :all, default: true
  scope :completed
  scope :running

  controller do
    def max_csv_records
      1_000_000
    end

    def destroy
      unless BackgroundJob.find(params[:id]).finished?
        flash[:error] = 'Running jobs cannot be deleted!'
        redirect_back(fallback_location: admin_background_jobs_path)
        return
      end

      destroy!
    end
  end

  index do
    selectable_column

    column :name
    column :created_at
    column 'State', sortable: :completed do |background_job|
      if background_job.finished? && !background_job.failed?
        status_tag('Completed', class: 'ok')
      elsif background_job.failed?
        status_tag('Failed', class: 'error')
      else
        status_tag('Running', class: 'warning', label: 'Running: ' + ('%.2f' % (background_job.progress * 100)) + '% completed')
      end
    end
    column :completed_at
    column :user

    customizable_default_actions(current_ability) do |background_job|
      background_job.finished? ? [] : [:destroy]
    end
  end

  show do |background_job|
    attributes_table do
      row :name
      row :user
      row 'State' do
        if background_job.finished? && !background_job.failed?
          status_tag('Completed', class: 'ok')
        elsif background_job.failed?
          status_tag('Failed', class: 'error')
        else
          status_tag('Running', class: 'warning', label: 'Running: ' + ('%.2f' % (background_job.progress * 100)) + '% completed')
        end
      end
      row :error_message if background_job.failed? && !background_job.error_message.blank?
      row :created_at
      row :updated_at
      row :completed_at
    end

    if background_job.results && background_job.results['zipfile']
      panel 'Download' do
        div(class: 'attributes_table') do
          table(border: 0, cellspacing: 0, cellpadding: 0) do
            tr do
              th { 'Zip file' }
              td { link_to('Download', download_zip_admin_background_job_path(resource)) }
            end
          end
        end
      end
    else
      unless background_job.results.blank?
        panel 'Results' do
          div(class: 'attributes_table') do
            table(border: 0, cellspacing: 0, cellpadding: 0) do
              background_job.results.each do |label, value|
                tr do
                  th { label }
                  td { simple_format(value) }
                end
              end
            end
          end
        end
      end
    end
  end

  member_action :download_zip, method: :get do
    background_job = BackgroundJob.find(params[:id])
    authorize! :read, background_job

    unless background_job.results && background_job.results['zipfile']
      flash[:alert] = 'No download available'
      redirect_back(fallback_location: admin_background_job_path(id: params[:id]))
      return
    end
    unless File.readable?(background_job.results['zipfile'])
      flash[:alert] = 'File not found'
      redirect_back(fallback_location: admin_background_job_path(id: params[:id]))
      return
    end

    send_file background_job.results['zipfile'], type: 'application/zip'
  end
end
