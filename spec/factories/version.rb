FactoryBot.define do
  factory :version do
    before(:create) do |version|
      user = FactoryBot.create(:user)
      version.item_id = user.id
      version.item_type = 'User'
      version.event = 'create'
      version.object = nil
      version.object_changes = user.attributes
    end
  end
end
