FactoryGirl.define do
  factory :center do
    name { Faker::Lorem.words(2).join(' ') }
    sequence(:code)
    study
    sequence(:domino_unid) do |n|
      "00BEEAFBEC35CFF7C12578CC00517D20"[0..-n.to_s.length] + n.to_s
    end
  end
end
