RSpec.describe Study do
  it 'has a valid factory' do
    expect(create(:study)).to be_valid
  end
end
