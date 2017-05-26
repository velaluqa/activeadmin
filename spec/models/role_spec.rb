RSpec.describe Role do
  it { should have_many(:notification_profile_roles) }
  it { should have_many(:notification_profiles) }

  it 'validates uniqueness of title attribute' do
    create(:role, title: 'My Role')
    new_role = build(:role, title: 'My Role')
    expect(new_role).not_to be_valid
  end

  describe '#add_permission' do
    describe 'for new permission' do
      describe 'for new role' do
        before(:each) do
          @role = build(:role)
          @role.add_permission(:read, Study)
        end

        it 'adds the new permission to the permissions array' do
          expect(@role.allows?(:read, Study)).to be_truthy
        end

        it 'does not save the permission' do
          expect(Permission.where(activity: :read, subject: Study).exists?).to be_falsy
        end
      end

      describe 'for existing role' do
        before(:each) do
          @role = create(:role)
          @role.add_permission(:read, Study)
        end

        it 'adds the new permission to the permissions array' do
          expect(@role.allows?(:read, Study)).to be_truthy
        end

        it 'saves the permission' do
          expect(@role.permissions.where(activity: :read, subject: Study).exists?).to be_truthy
        end
      end
    end

    describe 'for existing permission' do
      before(:each) do
        @role = create(:role, with_permissions: { Study => :read })
        expect(@role.permissions.where(activity: :read, subject: Study).count).to eq 1
        @role.add_permission(:read, Study)
      end

      it 'does nothing' do
        expect(@role.permissions.where(activity: :read, subject: Study).count).to eq 1
      end
    end
  end

  describe '#abilities' do
    before(:each) do
      @role = create(:role, with_permissions: {
                       [Study, Image] => :read,
                       User => :manage
                     })
    end

    it 'returns the ability strings for each permissions' do
      expect(@role.abilities).to match_array(%w[read_study read_image manage_user])
    end
  end

  describe '#abilities=' do
    before(:each) do
      @role = create(:role, with_permissions: {
                       Study => :read,
                       User => :manage
                     })
      @role.abilities = %w[manage_role manage_user]
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
      expect(@role.abilities).to match_array %w[manage_role manage_user]
    end
  end

  describe 'scope ::searchable' do
    let!(:role) { create(:role) }

    it 'selects search fields' do
      expect(Role.searchable.as_json)
        .to eq [{
          'id' => nil,
          'study_id' => nil,
          'study_name' => nil,
          'text' => role.title,
          'result_id' => role.id,
          'result_type' => 'Role'
        }]
    end
  end
end
