FactoryGirl.define do
  factory :center do
    sequence(:name) { |n| "Center #{n}" }
    sequence(:code)
    study
    sequence(:domino_unid) do |n|
      "00BEEAFBEC35CFF7C12578CC00517D20"[0..-n.to_s.length] + n.to_s
    end
  end
end
