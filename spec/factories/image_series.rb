FactoryGirl.define do
  factory :image_series do
    sequence(:name) { |n| "image_series#{n}" }
    visit
    patient { |is| is.visit.patient }
    imaging_date { Date.today }
    sequence(:series_number)
    sequence(:domino_unid) do |n|
      '00BEEAFBEC35CFF7C12578CC00517D20'[0..-n.to_s.length] + n.to_s
    end
  end
end
