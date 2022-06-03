Feature: Change Password
  In order to change a user's password,
  As authorized user,
  I can change a user's password.

  Background:
     Given a role "User Manager" with permissions:
       | User    | read, update, change_password |
     And a user "authorized.user" with:
      | name | Alex Authorized |
     And user "authorized.user" belongs to role "User Manager"
     And a role "Unauthorized" with permissions:
      | User | read, update |
     And a user "other.user" with:
      | name      | Udo Unathorized  |
      | email     | udo@email.com    |
     And user "other.user" belongs to role "Unauthorized" 

  Scenario: Unauthorized to change a user password
    When I sign in as user "other.user"
    And I browse to users list
    Then I see "Edit" in "Alex Authorized" row
    When I click "Edit" in "Authorized" row
    Then I don't see the "Password" field
    And I don't see the "Password confirmation" field

  Scenario: Authorized to change a user password
    When I sign in as user "authorized.user"
    And I browse to users list
    Then I see "Edit" in "other.user" row
    When I click "Edit" in "other.user" row
    Then I see "Edit User"
    When I fill in "Password" with "new.passsword"
    And I fill in "Password confirmation" with "new.passsword"
    And I click the "Update User" button
    Then I see "User was successfully updated"
    When I click "Logout" in the navigation menu
    Then I see "You need to sign in before continuing"
    When I fill in "Username" with "other.user"
    And I fill in "Password" with "new.passsword"
    And I click the "Sign in" button
    Then I see "Signed in successfully"
    And I receive an e-mail to "udo@email.com" with subject "Password Changed"
     