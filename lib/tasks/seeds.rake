namespace :erica do
  namespace :seed do
    task demo: :environment do
      def populate_study(options = {})
        center_count       = options[:centers] || 150
        patient_count      = options[:patients] || 200
        image_series_count = options[:image_series] || 200
        image_count        = options[:images] || 150

        progress = ProgressBar.create(
          format: "Populating #{options[:study].name}: %a %E %P% Processed: %c from %C",
          total: center_count * patient_count * image_series_count * image_count
        )
        center_count.times do
          center = FactoryGirl.create(:center, study: options[:study])

          patient_count.times do
            patient = FactoryGirl.create(:patient, center: center)

            image_series_count.times do
              image_series = FactoryGirl.create(:image_series, patient: patient)

              image_count.times do
                FactoryGirl.create(:image, image_series: image_series)

                progress.increment
              end
            end
          end
        end
      end

      @study1 = FactoryGirl.create(:study, name: 'Small Study')
      populate_study(
        study: @study1,
        centers: 10,
        patients: 10,
        image_series: 10,
        images: 10
      )
      @study2 = FactoryGirl.create(:study, name: 'Medium Study')
      populate_study(
        study: @study2,
        centers: 25,
        patients: 25,
        image_series: 25,
        images: 25
      )
      @study3 = FactoryGirl.create(:study, name: 'Large Study')
      populate_study(
        study: @study3,
        centers: 50,
        patients: 50,
        image_series: 50,
        images: 50
      )
    end
  end
end
