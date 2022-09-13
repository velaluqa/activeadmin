module ControllerMacros
  def login_user(role = :manage, subject_type = nil)
    before(:each) do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      user =
        FactoryBot.create(
          :user,
          :changed_password,
          :with_keypair,
          :with_role,
          role: role,
          subject_type: subject_type
        )
      sign_in(user)
    end
  end

  def login_user_with_abilities(&block)
    before(:each) do
      @request.env['devise.mapping'] = Devise.mappings[:user]
      @current_user = FactoryBot.create(:user, :changed_password, :with_keypair)
      sign_in @current_user

      ability_class = Class.new do
        attr_accessor :current_user
        include CanCan::Ability

        def can_with_undecorate?(action, subject, attribute = nil, *extra_args)
          undecorated_subject = Draper.undecorate(subject)
          can_without_undecorate?(
            action,
            undecorated_subject,
            attribute,
            *extra_args
          )
        end
        alias_method :can_without_undecorate?, :can?
        alias_method :can?, :can_with_undecorate?
      end
      ability = ability_class.new
      ability.current_user = @current_user
      ability.instance_eval(&block) if block_given?

      begin
        allow(@controller.send(:active_admin_authorization))
          .to receive(:cancan_ability).and_return(ability)
      rescue NoMethodError
        # Since we are calling a private method, we cannot check the
        # `#respond_to?` for @controller. Also `#private_method_defined?`
        # does not do the job. So we ignore the `NoMethodError`.
      end
      allow(@controller)
        .to receive(:current_ability).and_return(ability)
    end

    after(:each) do
      sign_out(:user)
    end
  end
end
