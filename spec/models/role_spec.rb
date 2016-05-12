RSpec.describe Role do
  it 'validates uniqueness of title attribute' do
    create(:role, title: 'My Role')
    new_role = build(:role, title: 'My Role')
    expect(new_role).not_to be_valid
  end

  describe '#abilities' do
    before(:each) do
      @role = create(:role, with_permissions: {
                       [Study, Image] => :read,
                       User => :manage })
    end

    it 'returns the ability strings for each permissions' do
      expect(@role.abilities).to match_array(%w(read_study read_image manage_user))
    end
  end

  describe '#abilities=' do
    before(:each) do
      @role = create(:role, with_permissions: {
                       Study => :read,
                       User => :manage })
      @role.abilities = %w(manage_role manage_user)
    end

    it 'keeps existing abilities' do
      expect(@role.abilities).to include 'manage_user'
    end

    it 'adds new permissions from abilities' do
      expect(@role.abilities).to include 'manage_role'
    end

    it 'removes non obsolete permissions' do
      expect(@role.abilities).not_to include 'read_study'
    end

    it 'persists the new permissions array to the database' do
      @role.save
      @role.reload
      expect(@role.abilities).to match_array %w(manage_role manage_user)
    end
  end
end
