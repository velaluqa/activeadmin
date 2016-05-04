FactoryGirl.define do
  factory :visit do
    patient
    sequence :visit_number
    sequence :visit_type
    sequence(:domino_unid) do |n|
      '00BEEAFBEC35CFF7C12578CC00517D20'[0..-n.to_s.length] + n.to_s
    end
  end
end
