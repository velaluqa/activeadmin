Feature: Destroy Users
  In order to delete users,
  As authorized user for destruction of users,
  I can destroy a user.

  Background:
     Given a role "User Manager" with permissions:
       | User    | read, destroy        |
       | Version | read                 |
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
     And I dismiss popup
     Then I see a row with "other.user"
     When I click "Delete" in "other.user" row
     And I provide "This is a comment" for browser prompt and confirm
     And I browse to users list
     Then I don't see a row with "other.user"
     When I click "Audit Trail" in the navigation menu
     And I click "View" in the first "Alex Authorized" row
     Then I see "This is a comment" in "Comment" row
     