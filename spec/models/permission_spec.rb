RSpec.describe Permission do
  describe '::from_ability' do
    it 'creates the correct permission' do
      permission = Permission.from_ability('read_image_series')
      expect(permission.activity).to eq(:read)
      expect(permission.subject).to eq(ImageSeries)
    end
    it 'raises error for wring ability string' do
      expect {
        Permission.from_ability('read_aa')
      }.to raise_error RuntimeError
    end
  end
end
