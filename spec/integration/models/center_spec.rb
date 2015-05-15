RSpec.describe Study do
  it 'has a valid factory' do
    expect(create(:center)).to be_valid
  end
end
