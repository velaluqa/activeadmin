initial_user = User.create(:name => 'Max Wolter', :username => 'profmaad', :password => 'change', :password_confirmation => 'change', :signature_password => 'signature', :signature_password_confirmation => 'signature')

Role.create(:user => initial_user, :subject_type => nil, :subject_id => nil, :role => :manage)
Role.create(:user => initial_user, :subject_type => nil, :subject_id => nil, :role => :image_manage)
