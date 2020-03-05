namespace :erica do
  namespace :helper do
    desc "Prints the "
    task :generate_encrypted_password, [:password] => [:environment] do |_, args|
      puts
      puts Devise::Encryptor.digest(User, args[:password])
    end
  end
end
