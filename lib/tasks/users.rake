namespace :erica do
  desc "Create a user and give him the application manager role"
  task :create_appadmin, [:username] => [:environment] do |t, args|
    if(args[:username].blank?)
      puts "No username given, aborting."
      next
    end

    user = User.where(:username => args[:username]).first
    if(user.nil?)
      user = User.create(:username => args[:username], :name => args[:username], :password => 'change', :password_confirmation => 'change')
      puts "Created user '#{user.username}'."
      puts "Initial password is 'change'."
    else
      puts "User '#{user.username}' already exists, adding application manager role."
    end

    if(user.roles.where(:subject_type => nil, :subject_id => nil, :role => Role::role_sym_to_int(:manage)).empty?)
      role = Role.create(:user => user, :subject_type => nil, :subject_id => nil, :role => :manage)
      puts "Application manager role added, done."
    else
      puts "User '#{user.username}' already has application manager role, doing nothing."
    end
  end
end
