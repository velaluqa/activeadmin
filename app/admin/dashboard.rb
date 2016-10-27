ActiveAdmin.register_page "Dashboard" do
  menu :priority => 1, :label => proc{ I18n.t("active_admin.dashboard") }

  content :title => proc{ I18n.t("active_admin.dashboard") } do
    panel 'My Studies' do
      if Study.accessible_by(current_ability).count == 0
        'You do not have any accessible studies'
      else
        table_for Study.accessible_by(current_ability) do
          column :name
          column :actions do |study|
            render partial: 'study_actions', locals: { study: study }
          end
        end
      end
    end

    unless(current_user.last_sign_in_at.nil?)
      panel 'Uploads since last login' do
        table_for ImageSeries.where('created_at >= ?', [current_user.last_sign_in_at]).includes(:patient => {:center => :study}).order('created_at asc') do
          column 'Study', :sortable => 'patient.center.study_id' do |image_series|
            link_to(image_series.study.name, admin_study_path(image_series.study))
          end
          column 'Patient', :sortable => :patient_id do |image_series|
            link_to(image_series.patient.name, admin_patient_path(image_series.patient))
          end

          column :name
          column :imaging_date
          column 'Import Date', :created_at
          column do |image_series|
            link_to('View', admin_image_series_path(image_series))
          end
        end
      end
    end

  end # content
end
