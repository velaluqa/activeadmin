RSpec.describe NotificationProfile, focus: true do
  describe '::triggered_by' do
    it 'is defined' do
      expect(NotificationProfile).to respond_to('triggered_by')
    end
  describe '#filter_matches?' do
    it 'is defined' do
      expect(NotificationProfile.new).to respond_to('filter_matches?')
    end
  end

  describe '#trigger' do
    it 'is defined' do
      expect(NotificationProfile.new).to respond_to('filter_matches?')
    end
  end
end
