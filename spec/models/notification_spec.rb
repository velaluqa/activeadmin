RSpec.describe Notification do
  it { should belong_to(:notification_profile) }
  it { should belong_to(:user) }
  it { should belong_to(:version) }
  it { should belong_to(:resource) }
end
