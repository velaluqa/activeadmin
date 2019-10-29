FactoryBot.define do
  factory :patient do
    center
    sequence(:subject_id)
    sequence(:images_folder)
    sequence(:domino_unid) do |n|
      '6FDDED9B730CB4D8C12579BB006E82C8'[0..-n.to_s.length] + n.to_s
    end
  end
end
