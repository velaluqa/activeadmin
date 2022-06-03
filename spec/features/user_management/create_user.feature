  Feature: Create Users
   In order to perform user managment,
   As authorized user for user creation,
   I can create users in the system.

   Background:
     Given a role "User Manager" with permissions:
       | User    | read, create |
     And a user "admin.user" with role "User Manager"

   Scenario: Unauthorized to create user
     When I sign in as a user with all permissions
     But I cannot create users
     When I browse to users list
     Then I don't see "New User"
     When I browse to "/admin/users/new"
     Then I see the unauthorized page

   Scenario: Authorized to create user
     When I sign in as user "admin.user"
     And I browse to users page
     Then I see "New User"
     When I click link "New User"
     And I fill in "Username" with "new.user"
     And I fill in "Email" with "my@email.com"
     And I fill in "Name" with "Carol"
     And I fill in "Password" with "passsword"
     And I fill in "Password confirmation" with "passsword"
     And I click the "Create User" button
     Then I see "User was successfully created"
     And I receive an e-mail to "my@email.com" with subject "Confirmation instructions"
     When I browse to users list
     Then I see a row with "new.user"
