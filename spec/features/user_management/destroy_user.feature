Feature: Destroy Users
  In order to delete users,
  As authorized user for destruction of users,
  I can destroy a user.

  Background:
     Given a role "User Manager" with permissions:
       | User    | read, destroy |
     And a user "authorized.user" with:
      | name | Alex Authorized |
     And user "authorized.user" belongs to role "User Manager"
     And a role "Unauthorized" with permissions:
      | User | read |
     And a user "other.user" with:
      | name | Udo Unauthorized | 
     And user "other.user" belongs to role "Unauthorized" 

   Scenario: Unauthorized to destroy a user
     When I sign in as user "other.user"
     And I browse to users list
     Then I don't see a row with "Delete"
     When I click "View" in "other.user" row
     Then I don't see "Delete User"

   Scenario: Authorized to destroy a user
     When I sign in as user "authorized.user"
     And I browse to users list
     Then I see "Delete" in "other.user" row
     When I click "Delete" in "other.user" row
     And I confirm alert
     Then I see "User was successfully destroyed"
     When I browse to users list
     Then I don't see a row with "other.user"
     