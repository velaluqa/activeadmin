module ControllerMacros
  def login_user(role = :manage, subject_type = nil)
    before(:each) do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      sign_in FactoryGirl.create(:user, :changed_password, :with_role,
                                 role: role,
                                 subject_type: subject_type)
    end
  end

  def login_user_with_abilities(&block)
    before(:each) do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      sign_in FactoryGirl.create(:user, :changed_password)
      ability = Object.new
      ability.extend(CanCan::Ability)
      ability.instance_eval(&block) if block_given?
      allow(@controller.send(:active_admin_authorization))
        .to receive(:cancan_ability).and_return(ability)
      allow(@controller)
        .to receive(:current_ability).and_return(ability)
    end

    after(:each) do
      sign_out(:user)
    end
  end
end
