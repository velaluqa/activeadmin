class AddUsernameToUsers < ActiveRecord::Migration
  class User < ActiveRecord::Base
    attr_accessible :username, :email
  end

  def change
    add_column :users, :username, :string

    User.reset_column_information
    User.all.each do |u|
      u.update_attributes!(username: u.email)
    end
  end
end
