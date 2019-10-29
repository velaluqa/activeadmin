FactoryBot.define do
  factory :user_role do
    transient do
      with_permissions({})
    end

    user
    role

    # Scope is nil by default, which means this user_roles
    # role-permissions will be granted system-wide.
    scope_object { nil }

    before(:create) do |user_role, evaluator|
      user_role.role =
        create(:role, with_permissions: evaluator.with_permissions)
    end
  end
end
