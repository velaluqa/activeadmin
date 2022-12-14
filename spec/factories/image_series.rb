FactoryBot.define do
  factory :image_series do
    transient do
      with_images { 0 }
    end

    sequence(:name) { |n| "image_series#{n}" }
    patient do |is|
      if is.visit
        is.visit.patient
      else
        create(:patient)
      end
    end
    imaging_date { Date.today }
    sequence(:series_number)
    sequence(:domino_unid) do |n|
      '00BEEAFBEC35CFF7C12578CC00517D20'[0..-n.to_s.length] + n.to_s
    end

    after(:create) do |image_series, context|
      1.upto(context.with_images) do |i|
        create(:image, image_series_id: image_series.id)
      end
    end
  end
end
