class AddUsernameToUsers < ActiveRecord::Migration[4.2]
  class User < ActiveRecord::Base
    attr_accessible :username, :email
  end

  def change
    add_column :users, :username, :string

    User.reset_column_information
    User.all.each do |u|
      u.update!(username: u.email)
    end
  end
end
