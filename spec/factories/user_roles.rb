FactoryGirl.define do
  factory :user_role do
    user
    role

    # Scope is nil by default, which means this user_roles
    # role-permissions will be granted system-wide.
    scope_object { nil }
  end
end
