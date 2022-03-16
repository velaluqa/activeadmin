FactoryBot.define do
  factory :active_admin_comment, class: "ActiveAdmin::Comment" do
    resource { create(:visit) }
    author { create(:user) }
    body { Faker::Lorem.paragraph }
    namespace { "admin" }
  end
end
