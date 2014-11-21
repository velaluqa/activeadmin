ActiveAdmin.register BackgroundJob do
  before_filter { @skip_sidebar = true }

  menu priority: 22
  config.filters = false
  config.comments = false
  actions :index, :show, :destroy

  scope :all, :default => true
  scope :completed
  scope :running

  controller do
    load_and_authorize_resource :except => :index

    def max_csv_records
      1_000_000
    end

    def scoped_collection
      end_of_association_chain.where(user_id: current_user.id)
    end

    def destroy
      if(not BackgroundJob.find(params[:id]).finished?)
        flash[:error] = 'Running jobs cannot be deleted!'
        redirect_to :back
        return
      end
      
      destroy!
    end
  end

  index do
    selectable_column

    column :name
    column :created_at
    column 'State', :sortable => :completed do |background_job|
      if(background_job.finished? and not background_job.failed?)
        status_tag('Completed', :ok)
      elsif(background_job.failed?)
        status_tag('Failed', :error)
      else
        status_tag('Running', :warning, :label => 'Running: '+ ('%.2f' % (background_job.progress*100))+ '% completed')
      end
    end
    column :completed_at

    customizable_default_actions(current_ability) do |background_job|
      background_job.finished? ? [] : [:destroy]
    end
  end

  show do |background_job|
    attributes_table do
      row :name
      row :user
      row 'State' do
        if(background_job.finished? and not background_job.failed?)
          status_tag('Completed', :ok)
        elsif(background_job.failed?)
          status_tag('Failed', :error)
        else
          status_tag('Running', :warning, :label => 'Running: '+ ('%.2f' % (background_job.progress*100))+ '% completed')
        end
      end
      row :error_message if(background_job.failed? and not background_job.error_message.blank?)
      row :created_at
      row :updated_at
      row :completed_at
    end

    if(background_job.results and background_job.results['zipfile'])
      panel 'Download' do
        div(:class => 'attributes_table') do
          table(:border => 0, :cellspacing => 0, :cellpadding => 0) do
            tr do
              th { 'Zip file' }
              td { link_to('Download', download_zip_admin_background_job_path(resource)) }
            end
          end
        end
      end
    else
      unless(background_job.results.blank?)
        panel 'Results' do
          div(:class => 'attributes_table') do
            table(:border => 0, :cellspacing => 0, :cellpadding => 0) do
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

    unless(background_job.results and background_job.results['zipfile'])
      redirect_to :back, alert: 'No download available'
      return
    end
    unless(File.readable?(background_job.results['zipfile']))
      redirect_to :back, alert: 'File not found'
      return
    end

    send_file background_job.results['zipfile'], type: 'application/zip'
  end
end
