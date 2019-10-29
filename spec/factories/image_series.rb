FactoryBot.define do
  factory :image_series do
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
  end
end
